extends RefCounted
class_name JSceneNodeGroupDiff

enum {
    JSCENE_NODE_DELTA_GROUP
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
var jscene_group:JSceneNodeGroup

var delta_group:JSceneDelta

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
    return not delta_group.is_unchanged()

#------------------------------------------
# Fonctions privées
#------------------------------------------

