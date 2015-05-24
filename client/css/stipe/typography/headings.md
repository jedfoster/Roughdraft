#Headings

Stipe's and Toadstool's approach to headings is more of a semantic use versus a presentational presetting of markup tags. 

Typically most will default style the `h1 - h6` tags and then this will be the referential design statement for the application. But there will be cases for SEO and other related semantic reasons that you will not want a `h1` to look like the 'h1'. 

##So, how do we do this?
In Stipe's [default typography](http://goo.gl/V81v3) settings, you will see that there are default styles set for `h1 - h6` tags. This is to set the base and simplify standard UI development. 

```scss
h1 {
  //font-size: 2em;  // user agent default
  @extend %headings_1;
}

h2 {
  //font-size: 1.5em;  // user agent default
  @extend %headings_2;
}
```

It is the `@extend` where all the magic happens. These extends are created like so from the [typography mixins](http://goo.gl/xdnQm)

```scss
%headings_1 {
  @include heading();
}

%headings_2 {
  @extend %headings_1;
  @include text($heading_2);
}
```

As a result we get the following CSS

```css
h2, h1 { font-size: 3.83333em; line-height: 1.17391em; margin-bottom: 0.3913em; color: #333333; font-weight: normal; font-family: "Helvetica Neue", Arial, sans-serif; }

h2 { font-size: 2.66667em; line-height: 1.125em; margin-bottom: 0.5625em; }
```

So lets say that in your design spec you will want to make a leading header in the view an `h1` but you want it to look like the `h2`? Well, through the magic of Sass, we can make this happen like so properly using the `@extend` function. 

```scss
.name_space {
  h1 {
    @extend %headings_2;
  }
}
``` 

Which gives us the following CSS

```css
h2, .name_space h1, h1 { font-size: 3.83333em; line-height: 1.17391em; margin-bottom: 0.3913em; color: #333333; font-weight: normal; font-family: "Helvetica Neue", Arial, sans-serif; }

h2, .name_space h1 { font-size: 2.66667em; line-height: 1.125em; margin-bottom: 0.5625em; }
```

So what we gain here is the ability to separate the semantics of heading tags from the look of the headers. Using the `@extend` function and how Stipe's architecture, we are able to redefine our CSS as needed without unnecessary duplicating style rules.  
