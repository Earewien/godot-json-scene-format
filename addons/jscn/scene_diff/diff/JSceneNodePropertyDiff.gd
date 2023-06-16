extends RefCounted
class_name JSceneNodePropertyDiff

enum {
    JSCENE_NODE_DELTA_PROPERTY
}

#------------------------------------------
# Signaux
#------------------------------------------

#------------------------------------------
# Exports
#------------------------------------------

#------------------------------------------
# Variables publiques
#------------------------------------------

var owner:JSceneNodeDiff
var jscene_property:JSceneNodeProperty

var delta_property:JSceneDelta

#------------------------------------------
# Variables privées
#------------------------------------------

#------------------------------------------
# Fonctions Godot redéfinies
#------------------------------------------

#------------------------------------------
# Fonctions publiques
#------------------------------------------

func has_delta() -> bool:
    return not delta_property.is_unchanged()

#------------------------------------------
# Fonctions privées
#------------------------------------------

