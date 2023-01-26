IF OBJECT_ID('[dbo].[spInsSazAplicaSurtimiento]','P') IS NOT NULLDROP PROCEDURE [dbo].[spInsSazAplicaSurtimiento]
GO
---------------------------------------------------------------------------
---Responsable: Moises Dominguez Mendoza
---Fecha:		Octubre 2022
---Descripcion: Transformacion Honduras - actualizacion surtimiento
-- Aplicacion:	VENTA ASISTENCIAS  (SAZRmpCertificado.exe) Sistemas SAZ
--------------------------------------------------------------------------- 
CREATE PROCEDURE dbo.spInsSazAplicaSurtimiento
@piNoPedido		INT,
@pcUserId		VARCHAR(8),    
@pcWS			VARCHAR(20)

AS
DECLARE     
@viTran2318		INT,   
@viError		INT,    
@vcDescError	VARCHAR(100),  
@viNoTienda		INT,  
@ViTipoSeg		INT,
@viProdid		INT,
@viPresupuesto	INT,
@viOpcion       TINYINT 
   
SET NOCOUNT ON    
   
SELECT @ViTipoSeg= 0, @viTran2318 = 0
IF NOT EXISTS (SELECT FINOPEDIDO FROM PEDIDO WITH(NOLOCK)WHERE FINOPEDIDO = @piNoPedido)
BEGIN
	SET @vcDescError = 'No existen datos del pedido'
	GOTO CtrlError
END

IF EXISTS (SELECT FINOPEDIDO FROM PEDIDO WITH(NOLOCK) WHERE FINOPEDIDO = @piNoPedido AND FIPEDSTAT = 0) 
BEGIN
		
	SELECT @viNoTienda = finotienda FROM CONTROL WITH(NOLOCK)
		
	IF EXISTS( SELECT fiNoPedido FROM Detalle_Pedido  WITH (NOLOCK) WHERE fiNoPedido = @piNoPedido 
	AND fiprodid IN (529253,529566)) ---se valida pedido para reg Seguro saldo deuda y empresario
	BEGIN
		SET @ViTipoSeg = 1   -----------SALDO DEUDA
	END
		 
	IF EXISTS( SELECT fiNoPedido FROM Detalle_Pedido  WITH (NOLOCK) WHERE fiNoPedido = @piNoPedido 
	AND fiprodid NOT IN (529253,529272, 529566) 
	AND (dbo.fnValidaSiAplicaReglaPorSku(197,fiprodid)=1)) ---se valida pedido para reg Seguro no ligados
	BEGIN
		SET @ViTipoSeg = 2	----------- CONTADO NO LIGADO
	END

	IF EXISTS( SELECT fiNoPedido FROM Detalle_Pedido  WITH (NOLOCK) WHERE fiNoPedido = @piNoPedido 
	AND fiprodid IN (99000023,99000024,99000025,99000026,99000027,99000028) 
	AND (dbo.fnValidaSiAplicaReglaPorSku(825,fiprodid)=1)) ---se valida pedido para reg Seguro no ligados
	BEGIN
		SET @ViTipoSeg = 3	----------- ASISTENCIAS
	END

	IF EXISTS( SELECT DP.fiNoPedido FROM Detalle_Pedido DP WITH (NOLOCK) WHERE fiNoPedido = @piNoPedido 
	AND fiprodid IN (1009303,1009304,1009308,1009305) 
	AND (dbo.fnValidaSiAplicaReglaPorSku(197,fiprodid)=1)) ---se valida pedido para reg Seguro no ligados
	BEGIN
		SET @ViTipoSeg = 4	----------- Familia Protegida
	END
		
	------------------------------------
	-- GENERACION DE TRANSACCION 2318 --
	------------------------------------
	EXEC @viTran2318 = spBDInsTransac
	@pfcTranWS    = @pcWS,
	@pfcTranUsr   = @pcUserId,
	@pfiTranTipo  = 2318,
	@pRetTipo     = 1,
	@pStatus      = 4
	IF @@ERROR <> 0 OR @viTran2318 <= 0
	BEGIN
		SET @vcDescError = 'No se recupero Numero de Transacción 2318'
		GOTO CtrlError
	END
		
	------------------------------
	-- INICIO DE LA TRANSACCION --
	------------------------------
	BEGIN TRANSACTION SURTESAZ
		   
		-------------------------------  
		-- VALIDAMOS EL TIPO DE VENTA   
		------------------------------- 			
		EXEC @viError		= spSurt
		@fiNoPedido		= @piNoPedido,
		@fcUserId		= @pcUserId,
		@fcWS			= @pcWS,
		@fiNoTienda		= @viNoTienda,
		@fiTranNo		= @viTran2318,
		@fcInven		= NULL,
		@fiUbica		= 1,
		@fiFactura		= NULL,
		@PUbiAlterna	= 1
		IF @@ERROR <> 0 OR @viError < 0    
		BEGIN    
			SET @vcDescError = 'Error al ejecutar spSurt en spInsSazAplicaSurtimiento'       
			GOTO CtrlError        
		END

		IF (@ViTipoSeg = 1)------- GENERA REGISTRO DE SALDO DEUDA
		BEGIN				
			EXEC @viError = spInsSAZGenReg5358  @piNoPedido, @viTran2318
			IF @@ERROR <> 0 OR @viError < 0    
			BEGIN
				SET @vcDescError = 'Problema al Ejecutar spInsSAZGenReg5358'
				GOTO CtrlError
			END	
		END
		ELSE IF @ViTipoSeg IN (2,4)
		BEGIN  
		IF @ViTipoSeg = 4
		BEGIN
			SELECT @viPresupuesto = fcFolioParam FROM PEDIDO WITH(NOLOCK) WHERE FINOPEDIDO = @piNoPedido

			IF EXISTS (SELECT fiFolioParam FROM TASAZCLIENTECONTADO  WITH(NOLOCK) WHERE fiFolioParam=@viPresupuesto)
			BEGIN
		
				SET @viOpcion=1
			END 
			ELSE 
			BEGIN	
				SET @viOpcion=0
			END 

			EXEC @viError = spInsSAZClienteCredMoc 
			@piPedidoSeg	= @piNoPedido 
			,@pcEmpleado	= @pcUserId
			,@piOpcion		= @viOpcion
			IF @@ERROR <> 0 OR @viError < 0    
			BEGIN
				SET @vcDescError = 'Problema al Ejecutar spInsSAZGenReg5378'
				GOTO CtrlError
			END	
		END
				
		EXEC @viError = spInsSAZGenReg5378  @piNoPedido, @viTran2318, 2318
		IF @@ERROR <> 0 OR @viError < 0    
		BEGIN
			SET @vcDescError = 'Problema al Ejecutar spInsSAZGenReg5378'
			GOTO CtrlError
		END	
					
		EXEC @viError = spInsSAZGenReg5379  @piNoPedido, @viTran2318
		IF @@ERROR <> 0 OR @viError < 0    
		BEGIN
			SET @vcDescError = 'Problema al Ejecutar spInsSAZGenReg5379'
			GOTO CtrlError
		END	
					
		EXEC @viError = spInsSAZGenReg5380  @piNoPedido, @viTran2318
		IF @@ERROR <> 0 OR @viError < 0    
		BEGIN
			SET @vcDescError = 'Problema al Ejecutar spInsSAZGenReg5380'
			GOTO CtrlError
		END	
		END
			
		ELSE IF(@ViTipoSeg = 3)
		BEGIN
			
			EXEC @viError = spGenReg5411 @piNoPedido, @viTran2318 , 2318
			IF @@ERROR <> 0 OR @viError < 0    
			BEGIN
				SET @vcDescError = 'Problema al Ejecutar spGenReg5409'
				GOTO CtrlError
			END	
					
			EXEC @viError = spGenReg5409 @piNoPedido, @viTran2318 
			IF @@ERROR <> 0 OR @viError < 0    
			BEGIN
				SET @vcDescError = 'Problema al Ejecutar spGenReg5409'
				GOTO CtrlError
			END						
					
			SELECT @viProdid= fiProdId FROM DETALLE_PEDIDO DET WITH(NOLOCK) INNER JOIN PEDIDO P 
			WITH(NOLOCK) ON DET.FINOPEDIDO=P.FINOPEDIDO WHERE DET.FINOPEDIDO= @piNoPedido
			
			IF @viProdid IN (99000024,99000028) -- ASITENCIA MOTOS & VIAL
			BEGIN
				EXEC @viError = spGenReg5406 @piNoPedido, @viTran2318
				IF @@ERROR <> 0 OR @viError < 0    
				BEGIN
					SET @vcDescError = 'Problema al Ejecutar spInsSAZGenReg5406'
					GOTO CtrlError
				END
			END
					
			IF @viProdid IN (99000025) -- ASISTENCIA HOGAR
			BEGIN
			
				EXEC @viError = spGenReg5407 @piNoPedido, @viTran2318
				IF @@ERROR <> 0 OR @viError < 0    
				BEGIN
					SET @vcDescError = 'Problema al Ejecutar spInsSAZGenReg5407'
					GOTO CtrlError
				END
			END
					
		END
			
		------------------------------       
		-- Actualizo la transaccion --  
		------------------------------                    
		EXEC @viError = spBDUpdTransac
		@pfiTranno		= @viTran2318,
		@pfcTranWS		= @pcWS,
		@pfcTranUsr		= @pcUserId,
		@pfiTranTipo	= 2318
		IF @@ERROR<> 0 OR @viError < 0
		BEGIN
			SET @vcDescError = 'Error al ejecutar spBDUpdTransac en spInsSazAplicaSurtimiento'                    
			GOTO CtrlError                    
		END		 
	---------------------------
	-- FIN DE LA TRANSACCION --
	---------------------------
	COMMIT TRANSACTION SURTESAZ
END
ELSE
BEGIN
	SET @vcDescError='EL ESTATUS DEL PEDIDO NO ES VALIDO'
	GOTO CtrlError
END

SELECT @viTran2318
SET NOCOUNT OFF
RETURN 0
   
-----------------------                    
-- Manejo de Errores --                    
-----------------------                    
CtrlError:          
	IF @@TRANCOUNT > 0          
	ROLLBACK TRANSACTION SURTESAZ    

	IF @viTran2318 > 0    
	BEGIN     
		EXEC @viError = spBDQuemaTransac @viTran2318, @pcWS, @pcUserId, 2318,0,0,@vcDescError                    
		IF @@ERROR <> 0 OR @viError < 0    
		BEGIN
			SET @vcDescError = 'Error al ejecutar spBDQuemaTransac en spInsSazAplicaSurtimiento'       
		END
	END         

	SET NOCOUNT OFF
	RAISERROR (@vcDescError,18,1)           
	RETURN -1



GO
EXEC dbo.spGrant 'dbo.spInsSazAplicaSurtimiento';