## 0.1.0

* Added `animateBackWith` to `PhysicsController` for compatibility with new `AnimationController` API in Flutter 3.29 (master).
* BREAKING: Bump min Flutter version to 3.27.0.

## 0.0.6+1

* Update `CHANGELOG.md`

## 0.0.6

* Use `Color.fromARGB` instead of `Color.from` to accommodate Flutter versions before 3.27.0.

## 0.0.5

* `PhysicsController` now implements the `AnimationController` interface, so it can (really) be used as a drop-in replacement for `AnimationController`.
* New methods added to `PhysicsController`: `toggle`, `animateTo`.

## 0.0.4

* Bug fix for PhysicsControllerMulti and PhysicsBuilderMulti.

## 0.0.3

* Bug fix for ASizedBox to normalize size.

## 0.0.2+1

* Update README.md

## 0.0.2

* Added comprehensive documentation and examples
* New PhysicsController variants (2D and Multi)
* New PhysicsAnimatedWidgetBaseState for ImplicitlyPhysicsAnimatedWidget, plus support for PhysicsAnimatedProperty (non-Tween-animated)
* New ASize, ASwitcher, and AValue widgets
* New PhysicsBuilder widgets (1D, 2D, Multi)
* Bug fixes and performance improvements

## 0.0.1

* Initial release.
