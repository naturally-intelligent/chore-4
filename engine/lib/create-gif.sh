gifsicle -O3 gifimage1.gif -o new-gifimage1.gif
convert -delay 10 -loop 0 *.png anim.gif
gifsicle --delay=5 -O3 --scale=0.5 anim.gif -o final.gif

