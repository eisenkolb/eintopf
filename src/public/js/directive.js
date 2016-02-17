angular.module("eintopf").directive("eintopfProjectSearch", ["$state", function($state){return{
    restrict: "A",
    scope: true,
    link: function(scope, element, attrs)
    {
        var autocomplete, largeOverlay = null;
        var eventHandler = function(event){
            largeOverlay.style.display = "block";
            autocomplete = largeOverlay.querySelector("#angucomplete input");
            autocomplete.focus();
			largeOverlay.addEventListener("click", function(event){
				if (event.target.id && event.target.id === largeOverlay.id){
					return largeOverlay.close();
				}
			});

            if ((event.which || event.keyCode) === /** ESC **/ 27){
                return largeOverlay.close();
            }
        };

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

        document.addEventListener("keydown", eventHandler);
    }
}}]);