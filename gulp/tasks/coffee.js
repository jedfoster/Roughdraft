var gulp = require('gulp');
var coffee = require('gulp-coffee');
var sourcemaps   = require('gulp-sourcemaps');
var handleErrors = require('../util/handleErrors');
var config = require('../config').coffee;

gulp.task('coffee', function() {
  gulp.src(config.src)
    .pipe(sourcemaps.init())
    .pipe(coffee(config.settings))
    .on('error', handleErrors)
    .pipe(sourcemaps.write())
    .pipe(gulp.dest(config.dest));
});
