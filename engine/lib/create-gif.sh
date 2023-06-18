# BASIC
convert -delay 10 -loop 0 *.png anim.gif
# CROP
convert -delay 5 -loop 0 -coalesce -repage 0x0 -crop 464x260+86+26 +repage *.png anim.gif
# COMPRESS
gifsicle -O3 gifimage1.gif -o new-gifimage1.gif
# SCALE
gifsicle --delay=5 -O3 --scale=0.5 anim.gif -o final.gif

# CUT DOWN VIDEO TIME
ffmpeg -i video.mp4 -ss 0:00 -t 0:30 output.mp4

# INCREASE CONVERT MEMORY
sudo vim /etc/ImageMagik../policy.xml
# FROM VIDEO TO GIF
ffmpeg -i cut-video.mkv -vf "fps=20,scale=640:-1:flags=lanczos" -c:v pam -f image2pipe - | convert -delay 5 - -loop 0 -layers optimize outputN.gif
