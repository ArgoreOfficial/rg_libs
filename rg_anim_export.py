import bpy, os
from math import degrees

selection = bpy.context.selected_objects
scene = bpy.context.scene
startFrame = scene.frame_start
endFrame = scene.frame_end
currentFrame = scene.frame_current

# File
file = open("D:/Dev/rg_libs/camera_path.lua", "w")


# iterate through the selected objects
for sel in selection:
    #cycle trough all the animated frames
    file.write("return {\n")
    for i in range(endFrame-startFrame+1):
        #get true frame number
        frame = i + startFrame
        #set frame and get the object's rotation
        scene.frame_set(frame)
        pos = sel.location
        rot = sel.rotation_euler
        file.write("  {pos=vec3(%f,%f,%f),pitch=%f,yaw=%f}" % (pos.x, pos.z, -pos.y, degrees(rot.x)-90, degrees(-rot.z)-90))
        
        if frame == endFrame:
            file.write("\n")
        else:
            file.write(",\n")
        
    file.write("}")
# close the file
file.close()

#restore original frame (not necessary)
scene.frame_set(currentFrame)