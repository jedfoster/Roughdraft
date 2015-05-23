var gulp    = require('gulp');
var config  = require('../config').production;
var size    = require('gulp-filesize');
var uglify  = require('gulp-uglify');
var del     = require('del');

gulp.task('clean', function (cb) {
  del(config.jsSrc, cb);
});

gulp.task('uglifyJs', ['browserify', 'clean'], function() {
  return setTimeout(function() {
    return gulp.src(config.jsSrc)
      .pipe(uglify())
      .pipe(gulp.dest(config.dest + '/js/'))
      .pipe(size());
  }, 50);
});

