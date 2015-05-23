#Stipe Plug-Ins
The following is a growing list of awesome work from others that I felt would be awesome to include in the Toadstool framework.

##hidpi.scss
Inspired by Kaelig's [`hidpi()` mixin](https://github.com/kaelig/hidpi) and [Tim Kadlec's work](http://timkadlec.com/2012/04/media-query-asset-downloading-results/) on optimizing the delivering of images, Stipe supports a simple mixing to 'retinafy' your site.

###How to use
Using Stipe's hidpi support you can either retinafy common elements in the UI or serve up different images.  

###hidpi common elements
Example: alter a visual element based on the resolution of the device, you could do the following:

```scss
#logo {
  border: 1px solid green;
  width: 100%;
  height: 200px;
  float: left;
  @include hidpi {
    border: 1px solid orange;
  }
}
```

In this example, all standard def devices will get the base green border. But anything that falls within the hidpi device spectrum will get the orange border. 

###hidpi images
The more common case is that you need to address two different resolution images. The process is simple. Use the `hidpi-image` mixing and pass in a few simple arguments. `$image`, `$width` and `$height`. By default the file extension is set to `png`, but you can change that with the final argument `$extension`.

The trick to the hipdi solution is that you need to place a corresponding image in the same directory with `_x2` in the name. Example `logo_x2.png` would work. 

Simply write your CSS rule like the following:

```scss
#logo {
  @include hidpi-image (logo, 250, 188);
}
```

If you were to want to use a `.jpg` file, it would look something like this:
```scss
#logo {
  @include hidpi-image (logo, 250, 188, jpg);
}
```
