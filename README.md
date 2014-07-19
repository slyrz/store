# store

Small program used to organize the files in my home directory. Currently
supports:

* Fonts  
will be copied to `.fonts/$family/$family-$weight.$ext` where the base name
has all spaces removed.

* Music  
will be copied to `Music/$artist/$album/$track $title.$ext`

## Requirements

The following libraries must be installed:

* `freetype`
* `ffmpeg` or `libav`

### License

store is released under MIT license.
You can find a copy of the MIT License in the [LICENSE](./LICENSE) file.
