(function () {
    'use strict';
    
    angular.module('ComprobadorComida', [])
    .controller('ComporbadorControler', MsgController);
    
    MsgController.$inject = ['$scope'];
    function MsgController($scope) {
      $scope.lista = "";
      $scope.Mensaje=""


      $scope.sayMessage = function () {
        return "Yaakov likes to eat healthy snacks at night!";
      };
    
      $scope.Comprobador = function () {
        const alimentos= $scope.lista
        if(alimentos===""){
            $scope.Mensajes("Por favor, introduzca los datos primero")
        }else{
            let arrayDeCadenas = alimentos.split(",");
            if(arrayDeCadenas.length <=3 )
            {
                $scope.Mensajes("¡Disfrute!");
            }else  if(arrayDeCadenas.length >3 ){
                $scope.Mensajes("¡Demasiado!");
            }
        }
    }
    $scope.Mensajes = function (Mensaje) {
        $scope.Mensaje = Mensaje;
      };
}
})();