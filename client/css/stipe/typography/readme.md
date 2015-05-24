#General typography

Much of your Typography has already been addressed with Toadstool. Simply use [Toadstool's config file](http://goo.gl/PqQSK) to address your `$font_size, $heading_1 - 6, $small_point_size and $large_point_size`. As well designate your `$primary_font_family, $secondary_font_family and $heading_font_family` variables.

##Typography functions
The functions included here are the part of Toadstool's design foundation. Functions for calculating `em` and `rem` values as well as calculating baseline heights for vertical rhythm. 

##Typography defaults
How does this work? Stipe's typography library contains a `_default.scss` file that is carried into the Toadstool project via the [_typograhy.scss](http://goo.gl/1YrDS) file. This file contains the basic bootstrap stylings for `html`, `h1-h6`, `p`, `b`, and `a` tags. Toadstool's [_typography.scss](http://goo.gl/d9yvC) file will mirror the default settings from Stipe. Feel free to edit as necessary, but I have found these pre-defined styles to be pretty stable. 

##Typography mixns
Default mixins to define headings and body text that includes the `baseline` function for automates `line-height` management. There are mixins for small, medium and large font sizes. A standard mixin for bulleted lists and a robust `font-face` mixin for adding new web fonts to your site.

##Typography extends
Part of the Stipe API is the use of [extends](http://goo.gl/iJfy9) for general use typography. Making use of these silent selectors will help to keep your UI consistent and your CSS nice and lean. These extends take advantage of the mixins already installed in Stipe. Uses included are headings 1-6, small, medium, and large font sizes, primary, secondary and heading font-families.

##The ems have it
It should be noted that Toadstool DOES NOT USE PIXELS for any values. At any time you need use a width/height/size value, use Stipe's [em function](http://goo.gl/rK2Ae), for example: `font-size: em(12);` or `width: em(100);`. The value passed into the em function are roughly equal to a pixel size. This will help to address conversions from pixel specifications to the more flexible em value. [Why Ems?](http://css-tricks.com/why-ems/)

Stipe's `em` function takes two arguments, `$target` and `$context`. By default `$context` is set to the `$font-size` you set in the your [config.scss](http://goo.gl/PqQSK) file. The function will take the value of the argument, divide it by the context and convert that to an em vlaue for the final output.

But why the second argument? The gotcha of ems is it's parental relationship. If at any time you redefined the parent font size, you need to redefine the context of this function. For example, if the parent was changed to `font-size: em(18);` and you wanted a header inside to be 24px, by resetting the context you will get the correct em value, like so: `font-size: em(24, 18);`.

Stipe also has a rem function that works the same way, example: `font-size: rem(24);` whereas this function takes the initial argument and divides by the font-size set in the `html` selector. Read more on rem from [snook.ca](http://goo.gl/85fhM), but use with caution, no support for IE8 and below.