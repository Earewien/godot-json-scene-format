extends RefCounted
class_name YAMLWriter

#------------------------------------------
# Signaux
#------------------------------------------

#------------------------------------------
# Exports
#------------------------------------------

#------------------------------------------
# Variables publiques
#------------------------------------------

#------------------------------------------
# Variables privées
#------------------------------------------

var _current_indent_level:int = 0
var _content:PackedStringArray = []

#------------------------------------------
# Fonctions Godot redéfinies
#------------------------------------------

#------------------------------------------
# Fonctions publiques
#------------------------------------------

func write(scene:PackedScene) -> void:
    _current_indent_level = 0
    _content = []

    _append_version()
    _append_tree(scene)

    print("--------------------")
    print("\n".join(_content))

var _cache_type:Dictionary = { }

#------------------------------------------
# Fonctions privées
#------------------------------------------

func _get_indent() -> String:
    return "  ".repeat(_current_indent_level)

func _indented(content:String) -> String:
    return "%s%s" % [_get_indent(), content]

func _append_version() -> void:
    _content.append(_indented("version: 1"))

func _append_tree(scene:PackedScene) -> void:
    var state:SceneState = scene.get_state()
    var all_nodes:Array[Dictionary] = []
    for n in state.get_node_count():
        all_nodes.push_back(_node_to_json(state, n))

    var connection_count:int = state.get_connection_count()
    if connection_count > 0:
        for conn_index in connection_count:
            var connection_flags:int = state.get_connection_flags(conn_index)
            var connection_binds:Array = state.get_connection_binds(conn_index)
            var connection_method:String = state.get_connection_method(conn_index)
            var connection_signal:String = state.get_connection_signal(conn_index)
            var connection_source:NodePath = state.get_connection_source(conn_index)
            var connection_target:NodePath = state.get_connection_target(conn_index)
            var connection_unbind_count:int = state.get_connection_unbinds(conn_index)

            for node in all_nodes:
                if node["path"] == connection_source:
                    if not node.has("connections"):
                        node["connections"] = []

                    var json_connection:Dictionary = {
                        "signal" : connection_signal,
                        "flags" : connection_flags,
                        "target_path" : connection_target,
                        "target_method" : connection_method
                    }
                    if not connection_binds.is_empty():
                        json_connection["binds"] = []
                        for bind_arg in connection_binds:
                            json_connection["binds"].push_back(var_to_str(bind_arg))
                    if connection_unbind_count > 0:
                        json_connection["unbind"] = connection_unbind_count
                    node["connections"].push_back(json_connection)
                    break

    var current_path:NodePath = ^""
    for node in all_nodes:
        _content.append(_indented("%s:" % node["name"]))
        _current_indent_level += 1
        if node.has("groups"):
            _content.append(_indented("groups:"))
            _current_indent_level += 1
            for group in node["groups"]:
                _content.append(_indented("- %s" % group))
            _current_indent_level -= 1
        if node.has("properties"):
            _content.append(_indented("properties:"))
            _current_indent_level += 1
            for prop_name in node["properties"].keys():
                _save_property(node["type"], prop_name, node["properties"][prop_name])
            _current_indent_level -= 1
        _current_indent_level -=1

        var this_node_path:NodePath = node["path"]
        _current_indent_level += (this_node_path.get_name_count() - current_path.get_name_count())
        current_path = this_node_path

func _save_property(owner:Variant, name:String, value:Variant) -> void:
    if owner and !owner.is_empty():
        var ref_value:Variant
        if _cache_type.has(owner):
            ref_value = _cache_type[owner]
        else:
            ref_value = ClassDB.instantiate(owner)
            _cache_type[owner] = ref_value
        for prop in ref_value.get_property_list():
            if prop["name"] == name:
                var default_value:Variant = ref_value.get(name)
                if default_value == value:
                    return

    if value is Resource:
        _save_resource(name, value)
    elif value is Dictionary:
        _content.append(_indented("- %s :" % ["''" if name.is_empty() else name]))
        _current_indent_level += 1
        for key in value.keys():
            _save_property(null, var_to_str(key), value[key])
        _current_indent_level -= 1
#    elif value is Array:
#        _content.append(_indented("- %s: [" % ["''" if name.is_empty() else name]))
#        _current_indent_level += 2
#        for val in value:
#            _save_value(val)
#        _current_indent_level -= 1
#        _content.append(_indented("]"))
#        _current_indent_level -= 1
    else:
        var raw_prop_value:String = var_to_str(value)
        if raw_prop_value.begins_with("\"") and raw_prop_value.ends_with("\""):
            raw_prop_value = raw_prop_value.substr(1, raw_prop_value.length() - 2)
        var prop_value:PackedStringArray = raw_prop_value.split("\n")
        if prop_value.size() == 0:
            _content.append(_indented("- %s: ''" % ["''" if name.is_empty() else name]))
        elif prop_value.size() == 1:
            _content.append(_indented("- %s: %s" % ["''" if name.is_empty() else name, prop_value[0]]))
        else:
            _content.append(_indented("- %s: |+" % "''" if name.is_empty() else name))
            _current_indent_level += 2
            for prop_value_line in prop_value:
                _content.append(_indented(prop_value_line))
            _current_indent_level -= 2

func _save_value(value:Variant) -> void:
    _content.append(_indented("%s" % var_to_str(value)))

func _save_resource(name:String, resource:Resource) -> void:
    if not resource.resource_path.is_empty():
        _content.append(_indented("- %s: ExtResource(%s)" % ["''" if name.is_empty() else name, resource.resource_path]))
    else:
        _content.append(_indented("- %s: InternalResource(%s)" % ["''" if name.is_empty() else name, resource.get_class()]))
        _current_indent_level += 1
        for p in resource.get_property_list():
            if p["usage"] & PROPERTY_USAGE_STORAGE == PROPERTY_USAGE_STORAGE:
                var prop_value:Variant = resource.get(p["name"])
                _save_property(resource.get_class(), p["name"], prop_value)
        _current_indent_level -= 1

func _node_to_json(state:SceneState, node_index:int) -> Dictionary:
    var json:Dictionary = { }

    var node_name:String = state.get_node_name(node_index)
    var node_type:String = state.get_node_type(node_index)
    var node_path:NodePath = state.get_node_path(node_index)
    var node_groups:PackedStringArray = state.get_node_groups(node_index)

    json["name"] = node_name
    json["type"] = node_type
    json["path"] = node_path
    if not node_groups.is_empty():
        json["groups"] = node_groups

    var property_count:int = state.get_node_property_count(node_index)
    if property_count > 0:
        json["properties"] = { }
        for prop_index in property_count:
            var property_name:String = state.get_node_property_name(node_index, prop_index)
            var property_value:Variant = state.get_node_property_value(node_index, prop_index)
            json["properties"][property_name] = property_value

    return json
