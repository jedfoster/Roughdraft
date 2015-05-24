# Grids
Stipe provides 12, 16, and 24 column grids based on the original [960.gs](http://960.gs/) solution.


## Placeholder classes
You can use the grid without placing presentational classes on your markup by applying Stipe's placeholder classes.

This Sass:

```sass
nav {
  @extend %grid_12of12;

  @media #{$mobile} {
    @extend %grid_4of4;
  }
}

.gallery img {
  @extend %grid_4of12;

  @media #{$mobile} {
    @extend %grid_4of4;
  }
}
```

Yields this CSS:

```css
nav, .gallery img {
  float: left;
  margin-left: 1.04167%;
  margin-right: 1.04167%;
  width: 31.25%;
}

@media screen and (max-width: 40em) {
  nav, .gallery img {
    float: left;
    margin-left: 3.125%;
    margin-right: 3.125%;
    width: 93.75%;
  }
}
```

## Building custom grid widths and nesting

If you require more customization for a given column, use Stipe's grid mixin: `@include grid($col_count)`, replacing `$col_count` with the number of columns you need.

When nesting grids, since Stipe defaults to percentages, you need to make sure to reset your context by passing in the `$grid_context` argument.

## Grid arguments
Additional arguments can be passed into the grid mixin to include `$grid_padding_l` `$grid_padding_r` `$grid_padding_tb` `$grid_border` `$border_place` `$grid_uom` `$col_gutter` `$grid_type` `$grid_align` `$grid_context`

* `$grid_padding_l` => adds padding LEFT, takes integer value
* `$grid_padding_r` => adds padding RIGHT, takes integer value
* `$grid_padding_tb` => adds padding TOP and BOTTOM, takes integer value
* `$grid_border` => takes integer value, adds border using `$border_color` and `$standard_border_style` configs found in `_config.scss`.
* `$border_place` => arguments are `left` and `right`. Argument will place a single border on either the left or right side of the block.
* `$grid_uom` => set to percent by default, accepts `em` as argument.
* `$col_gutter` => takes integer to adjust col gutter
* `$grid_align` => takes `center` as argument
* `$grid_context` => Adjusts column widths based on nested grid context. Necessary when calculating with percentages
