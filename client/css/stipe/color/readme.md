#How does color work?

In your Toadstool style guide, `style.scss` calls in local `_config.scss`. Local `_config.scss` can over-write primary colors and pass values to `color/color_math` and `color/grayscale_math`.

`color/color_math` imports `stipe/color/default_color_pallet` to ensure that un-updated default values are carried forward. 

In your Toadstool style guide`toadstool.scss` imports `color/extends.scss` from the local style guide so that the extends have the correct color reference. But it is in `stipe/toadstool/ui_patterns/_color_grid.scss` where these extended values are given classes that only appear in the `toadstool.css`. This principle is needed so that the site's extends will create colors from the appropriate context and the presentational classes only live in the `toadstool.css` doc.  

