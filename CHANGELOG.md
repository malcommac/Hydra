<p align="center" >
  <img src="https://raw.githubusercontent.com/malcommac/Hydra/develop/hydra-logo.png" width=210px height=204px alt="Hydra" title="Hydra">
</p>

## CHANGELOG

* Version **[0.9.7](#097)**
* Version **[0.9.4](#094)**
* Version **[0.9.3](#093)**
* Version **[0.9.2](#092)**
* Version **[0.9.1](#091)**


https://github.com/malcommac/Hydra/issues/25

<a name="097" />

## Hydra 0.9.7
---
- **Release Date**: 2017-07-09
- **Zipped Version**: [Download 0.9.7](https://github.com/malcommac/Hydra/releases/tag/0.9.7)

### Important Notice

Since 0.9.7 Hydra implements Cancellable Promises. In order to support this new feature we have slightly modified the `Body` signature of the `Promise`; in order to make your source code compatible you just need to add the third parameter along with `resolve`,`reject`: `operation`.
`operation` encapsulate the logic to support `Invalidation Token`. It's just and object of type `PromiseStatus` you can query to see if a Promise is marked to be cancelled from the outside.
If you are not interested in using it in your Promise declaration just mark it as `_`.


To sum up your code:

```swift
return Promise<Int>(in: .main, token: token, { resolve, reject in ...
```

needs to be:

```swift
return Promise<Int>(in: .main, token: token, { resolve, reject, operation in // or resolve, reject, _
```

### New Features:

- [#25](https://github.com/malcommac/Hydra/pull/25) Added support for Cancellable Promises via `InvalidationToken`. [See the documentation](https://github.com/malcommac/Hydra/tree/feature/0.9.7#cancellablepromises) for more info.

Thanks to [Maurizio Panzica](https://www.facebook.com/maurizio.panzica?ref=br_rs) to point me to the right solution to support cancellable promises feature.

<a name="094" />

## Hydra 0.9.4
---
- **Release Date**: 2017-03-21
- **Zipped Version**: [Download 0.9.4](https://github.com/malcommac/Hydra/releases/tag/0.9.4)

- [#22](https://github.com/malcommac/Hydra/pull/22) Fixed an issue with `any` operator which in several occasions does not work.
- [#24](https://github.com/malcommac/Hydra/pull/24) Fixed never chainable if return rejected promise in `recover` operator closure.
- [#26](https://github.com/malcommac/Hydra/pull/26) Added concurrency argument in `all` operator; it allows you to set the number of max concurrent promises running for an all task in order to reduce memory and cpu footprint.
- [#28](https://github.com/malcommac/Hydra/pull/28) Fixed Promise's memory leak
- [#29](https://github.com/malcommac/Hydra/pull/29) Cleaned up the process of running the observer
- [#18](https://github.com/malcommac/Hydra/pull/18), [#20](https://github.com/malcommac/Hydra/pull/20) Refactoring of several func inside the Promise's class.


<a name="093" />

## Hydra 0.9.3
---
- **Release Date**: 2017-03-06
- **Zipped Version**: [Download 0.9.3](https://github.com/malcommac/Hydra/releases/tag/0.9.3)

- [#15](https://github.com/malcommac/Hydra/pull/15) Added conditional block to retry operator to determine whether retry is possible
- [#14](https://github.com/malcommac/Hydra/pull/14) Minor fixes for documentation (`zip` and `all` funcs)

<a name="092" />

## Hydra 0.9.2
---
- **Release Date**: 2017-02-21
- **Zipped Version**: [Download 0.9.2](https://github.com/malcommac/Hydra/releases/tag/0.9.2)

- [#1](https://github.com/malcommac/Hydra/pull/1) Added `async` function to create new promises or execute a block of code in another context.
- [#12](https://github.com/malcommac/Hydra/pull/12) `all()` is now visible outside the library.
- [#10](https://github.com/malcommac/Hydra/pull/10) Fixed an issue while using `await()` due to a constraint with non labeled Swift params.
- [#13](https://github.com/malcommac/Hydra/pull/13) `any()` is now visible outside the library

<a name="091" />

## Hydra 0.9.1
---
- **Release Date**: 2017/02/15
- **Zipped Version**: [Download 0.9.1](https://github.com/malcommac/Hydra/releases/tag/0.9.1)

- [#8](https://github.com/malcommac/Hydra/pull/8) Single framework for multiple platforms
