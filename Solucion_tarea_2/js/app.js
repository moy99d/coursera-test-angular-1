
(function () {
    'use strict';
      
  angular.module('ListaDeTienda', [])
  .controller('ToBuyControllery', ToBuyControllery)
  .controller('AlreadyBoughtController', AlreadyBoughtController)
  .service('ShoppingListCheckOffService', ShoppingListCheckOffService);


  ToBuyControllery.$inject = ['ShoppingListCheckOffService'];
  function ToBuyControllery(ShoppingListCheckOffService) {
    var showList = this;
     showList.items = ShoppingListCheckOffService.getItems();
    showList.removeItem = function (itemIndex) {
        
        ShoppingListCheckOffService.addItem(showList.items[itemIndex].name,showList.items[itemIndex].quantity,)
        ShoppingListCheckOffService.removeItem(itemIndex);

  }
}
  
  AlreadyBoughtController.$inject = ['ShoppingListCheckOffService'];
  function AlreadyBoughtController(ShoppingListCheckOffService) {
    var itemAdder = this;

    itemAdder.item2 = ShoppingListCheckOffService.getItemsComprados();

  }

  
function ShoppingListCheckOffService() {
    var service = this;

    // List of shopping items
    var items = [ {
        name: "Botellas Agua",
        quantity: "15"
      },
      {
        name: "Chocolates",
        quantity: "20"
      },
      {
        name: "Sabritas",
        quantity: "25"
      },
      {
        name: "Refrescos",
        quantity: "15"
      },
      {
          name: "Paletas",
          quantity: "5"
        }];
    var item2 =[];
console.log(item2.length)
    
    service.addItem = function (itemName, quantity) {
      var item = {
        name: itemName,
        quantity: quantity
      };
      item2.push(item);
  
    };
  
    service.removeItem = function (itemIndex) {
     items.splice(itemIndex, 1);
    };
  
    service.getItems = function () {
      return items;
    };

    service.getItemsComprados = function () {
        return item2;
      };
  }
  


  
})();