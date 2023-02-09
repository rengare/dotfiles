 #!/bin/bash 
 
if [ $(yabai -m config layout) = "bsp" ]; then
  yabai -m config layout stack
else
  yabai -m config layout bsp 
fi

