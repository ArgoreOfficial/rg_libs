import bpy

def float2string(x, p):
    return ('%.*f' % (p, x)).rstrip('0').rstrip('.')

def write_faces(polygons, obj):
    me = obj.data
    
    verts = me.vertices
    uv_layer = me.uv_layers.active.data
    materials = [i.material for i in obj.material_slots]
    
    for f in me.polygons:
        print("Polygon index: {:d}, length: {:d}".format(f.index, f.loop_total))
        
        v = []
        n = []
        uv = []
        for loop_index in range(f.loop_start, f.loop_start + f.loop_total):
            uv.append(uv_layer[loop_index].uv.x)
            uv.append(uv_layer[loop_index].uv.y)
        
        for i in f.vertices:
            # position
            v.append(verts[i].co[0])
            v.append(verts[i].co[2])
            v.append(-verts[i].co[1])
            # normal
            n.append(verts[i].normal[0])
            n.append(verts[i].normal[2])
            n.append(-verts[i].normal[1])
        
        c = (1.0,1.0,1.0)
        if f.material_index >= 0:
            mat = materials[f.material_index]
            nodes = [i.type for i in mat.node_tree.nodes]
            if 'RGB' in nodes:
                c = mat.node_tree.nodes['RGB'].outputs[0].default_value[0:3]
            elif 'EMISSION' in nodes:
                c = mat.node_tree.nodes['Emission'].inputs[0].default_value[0:3]
        
        rgb = tuple(round(255*i**(1.0/2.2)) for i in c) 
        
        face_str = '{'
        face_str += '%d,%d,%d, ' % rgb
        face_str += "p={" + ','.join(float2string(i, 2) for i in v) + "}, "
        face_str += "n={" + ','.join(float2string(i, 2) for i in n) + "}, "
        face_str += "uv={" + ','.join(float2string(i, 2) for i in uv) + "}, "
        face_str += '}'
        polygons.append(face_str)

def write_some_data(context, filepath, use_some_setting):
    print("running write_some_data...")
    f = open(filepath, 'w')
    fw = f.write
    fw('return {\n')
    l = []
    for obj in context.selected_objects:
        write_faces(l, obj)
    
    str = "\t"
    str += ',\n\t'.join(l)
    str += "\n"
    
    fw(str)
    fw('}\n')
    f.close()

    return {'FINISHED'}


# ExportHelper is a helper class, defines filename and
# invoke() function which calls the file selector.
from bpy_extras.io_utils import ExportHelper
from bpy.props import StringProperty, BoolProperty, EnumProperty
from bpy.types import Operator


class ExportSomeData(Operator, ExportHelper):
    """Export as rg_3d Model"""
    bl_idname = "export_test.some_data"  # important since its how bpy.ops.import_test.some_data is constructed
    bl_label = "Export rg_3d Model"

    # ExportHelper mix-in class uses this.
    filename_ext = ".lua"

    filter_glob: StringProperty(
        default="*.lua",
        options={'HIDDEN'},
        maxlen=255,  # Max internal buffer length, longer would be clamped.
    )

    # List of operator properties, the attributes will be assigned
    # to the class instance from the operator settings before calling.
    use_setting: BoolProperty(
        name="Example Boolean",
        description="Example Tooltip",
        default=True,
    )

    type: EnumProperty(
        name="Example Enum",
        description="Choose between two items",
        items=(
            ('OPT_A', "First Option", "Description one"),
            ('OPT_B', "Second Option", "Description two"),
        ),
        default='OPT_A',
    )

    def execute(self, context):
        return write_some_data(context, self.filepath, self.use_setting)


# Only needed if you want to add into a dynamic menu
def menu_func_export(self, context):
    self.layout.operator(ExportSomeData.bl_idname, text="rg_3d (.lua)")


# Register and add to the "file selector" menu (required to use F3 search "Text Export Operator" for quick access).
def register():
    bpy.utils.register_class(ExportSomeData)
    bpy.types.TOPBAR_MT_file_export.append(menu_func_export)


def unregister():
    bpy.utils.unregister_class(ExportSomeData)
    bpy.types.TOPBAR_MT_file_export.remove(menu_func_export)


if __name__ == "__main__":
    register()

    # test call
    bpy.ops.export_test.some_data('INVOKE_DEFAULT')
