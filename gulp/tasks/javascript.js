var gulp = require('gulp');
var config = require('../config').javascript;

gulp.task('javascript', function() {
   gulp.src(config.src)
    .pipe(gulp.dest(config.dest));
});
