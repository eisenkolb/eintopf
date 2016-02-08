angular.module("eintopf").directive("filterSidebar", [function(){return{
    restrict: "A",
    link: function(scope, element, attrs)
    {
        document.addEventListener("keydown", function(event){
            if (scope.searchElem === undefined){
                scope.searchElem = document.getElementById(element[0].id);
            }

            scope.$apply(scope.searchView = true);
            scope.searchElem.focus();

            if ((event.which || event.keyCode) === /** ESC **/ 27){
                scope.searchTerm = "";
                scope.$apply(scope.searchView = false);
            }
        });
    }
}}]);