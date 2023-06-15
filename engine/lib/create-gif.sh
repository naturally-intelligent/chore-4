# BASIC
convert -delay 10 -loop 0 *.png anim.gif
# CROP
convert -delay 5 -loop 0 -coalesce -repage 0x0 -crop 464x260+86+26 +repage *.png anim.gif
# COMPRESS
gifsicle -O3 gifimage1.gif -o new-gifimage1.gif
# SCALE
gifsicle --delay=5 -O3 --scale=0.5 anim.gif -o final.gif

# FROM VIDEO
ffmpeg -i devday-battle1.mkv -vf "fps=10,scale=320:-1:flags=lanczos" -c:v pam -f image2pipe - | convert -delay 10 - -loop 0 -layers optimize output.gif
