'use strict';

module.exports = function(grunt) {
	// Unified Watch Object
	var watchFiles = {
		serverJS: ['gruntfile.js', 'app.js', 'app/**/*.js'],
		testJS: ['test/*/*.js'],
	};

	// Project Configuration
	grunt.initConfig({
		pkg: grunt.file.readJSON('package.json'),
		watch: {
			serverJS: {
				files: watchFiles.serverJS,
				tasks: ['jshint'],
				options: {
					livereload: true
				}
			}
		},
		jshint: {
			all: {
				src: watchFiles.serverJS.concat(watchFiles.testJS),
				options: {
					jshintrc: true
				}
			}
		},
		env: {
			test: {
				NODE_ENV: 'test'
			}
		},
		mochacli: {
			options: {
				harmony: true
			},
			test : {
				src: watchFiles.testJS,
				options : {
					reporter: 'spec',
					timeout: 5 * 1000
				}
			},
		}
	});

	// Load NPM tasks
	require('load-grunt-tasks')(grunt);

	// Making grunt default to force in order not to break the project.
	grunt.option('force', true);

	// Lint task(s).
	grunt.registerTask('lint', ['jshint']);

	// Test task.
	grunt.registerTask('test', ['env:test', 'lint', 'mochacli']);
};
