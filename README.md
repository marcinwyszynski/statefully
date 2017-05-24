# Statefully: immutable state library for Ruby

[![Gem Version](https://badge.fury.io/rb/statefully.svg)](https://badge.fury.io/rb/statefully) [![codebeat badge](https://codebeat.co/badges/f40e18a8-836b-4a47-a1ed-113ce200a529)](https://codebeat.co/projects/github-com-marcinwyszynski-statefully-master) [![codecov](https://codecov.io/gh/marcinwyszynski/statefully/branch/master/graph/badge.svg)](https://codecov.io/gh/marcinwyszynski/statefully) [![Codefresh build status]( https://g.codefresh.io/api/badges/build?repoOwner=marcinwyszynski&repoName=statefully&branch=master&pipelineName=deploy&accountName=marcinwyszynski&type=cf-2)]( https://g.codefresh.io/repositories/marcinwyszynski/statefully/builds?filter=trigger:build;branch:master;service:591f06cfdc54860001d23eb9~deploy)

Statefully is an immutable state library to serve as a building block for awesome, composable APIs. Its core concept is `State`, which can be either a `Success`, a `Failure` or `Finished` (successful but terminal). Code speaks louder than words, so here's a few examples:

```
> state = Statefully::State.create
=> #<Statefully::State::Success>
> state = state.succeed(key: 'val')
=> #<Statefully::State::Success key="val">
> state = state.fail('Oh no')
=> #<Statefully::State::Failure key="val", error="\"Oh no\"">
> state.resolve
RuntimeError: Oh no
        [STACK TRACE]
> state.previous.resolve
=> #<Statefully::State::Success key="val">
> state = state.previous.finish
=> #<Statefully::State::Finished key="val">
state.succeed(new_key: 'new_val')
NoMethodError: undefined method `succeed' for
  #<Statefully::State::Finished key="val">
        [STACK TRACE]
```

The core API is really simple - `State::Success` has three methods, each of which produces an instance of `State`: `succeed` will produce another `State::Success`, `finish` will produce a `State::Finished` and `fail` will produce a `State::Failure`. Each `State` can access its predecessor by calling the `previous` method. The rest of the [`State` API](http://www.rubydoc.info/gems/statefully/Statefully/State) are just convenience wrappers, except perhaps for the `diff` method, described below.

# Diffs

Since `State` always knows about its predecessor, we can use the `diff` method to compare the two:

```
> state = Statefully::State.create
=> #<Statefully::State::Success>
> state = state.succeed(key: 'val')
=> #<Statefully::State::Success key="val">
> state.diff
=> #<Statefully::Diff::Changed added={key: "val"}>
> state = state.update(key: 'another')
NoMethodError: undefined method `update' for
  #<Statefully::State::Success key="val">
        [STACK TRACE]
> state = state.succeed(key: 'another')
=> #<Statefully::State::Success key="another">
> state.diff
=> #<Statefully::Diff::Changed
     changed={key: #<Statefully::Change current="another", previous="val">}>
```

In fact, because each `State` knows about its predecessor, we can `diff` recursively. A convenience method called `history` does just that, with newest changes first:

```
> state.history
=> [#<Statefully::Diff::Changed
      changed={key: #<Statefully::Change current="another", previous="val">}>,
    #<Statefully::Diff::Changed added={key: "val"}>,
    #<Statefully::Diff::Created>]
```

[`Diff` API](http://www.rubydoc.info/gems/statefully/Statefully/Diff) is very simple, too. You can compare arbitrary `State`s using `Statefully::Diff.create`, but be aware that we assume state keys are never removed - they may be added or their values may change. So, it only makes sense to compare `State`s within the scope of the same history.

