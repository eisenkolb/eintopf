angular.module("eintopf").directive("eintopfProjectSearch", ["$state", function($state){return{
    restrict: "A",
    scope: true,
    link: function(scope, element, attrs)
    {
        var autocomplete, largeOverlay = null;

        largeOverlay = document.getElementById("project-search");
        largeOverlay.close = function(){
            autocomplete.value = "";
            largeOverlay.style.display = "none";
        };

        scope.$watch("selectedProject", function(selected){
            if (!selected) return;
            setTimeout(largeOverlay.close, 1);
            $state.go("cooking.projects.recipe", {id: scope.selectedProject.originalObject.id});
        });

        document.addEventListener("keydown", function(event){
            largeOverlay.style.display = "block";
            autocomplete = largeOverlay.querySelector("#angucomplete input");
            autocomplete.focus();

            if ((event.which || event.keyCode) === /** ESC **/ 27){
                largeOverlay.close();
            }
        });
    }
}}]);