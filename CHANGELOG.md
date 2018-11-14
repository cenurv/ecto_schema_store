# Change Log #

## 3.0.0 ##

* Ecto 3.0 compatibility, to use Ecto 2 downgrade to EctoSchemaStore 2.4.1.

## 2.4.1 ##

* Corrected logging name for failed update.

## 2.4.0 ##

* Added `logging` option when creating a store. This will cause the store log edit actions using `info` for success and `warn` for changes that could not be completed.

Sample Insert Output:

```
iex(1)> PersonStore.insert [], changeset: :insert_changeset, errors_to_map: :person
[warn] Elixir.Person action `insert` using opts `[timeout: 5000, sync: true, changeset: :insert_changeset, errors_to_map: :person]` failed due to %{"person.email" => ["can't be blank"], "person.name" => ["can't be blank"]}
```

## 2.3.2 ##

* Changed no changset inserts and updates (including insert_fields and update_fields) to always update fields regardless of it is actually a change.

## 2.3.1 ##

* Fix to unquote variable in Proxy macro.

## 2.3.0 ##

* Added Store proxy method generation to allow schema modules to expose the store modules directly.

## 2.2.4 ##

* Return `nil` when passing `nil` into `one` for the filter params or id. Previously was throwing an unmatched `build_query` function call error.
* Fixed `count_records` when counting all records in a table with no filter options. Function can now take no parameters. `PersonStore.count_records`.

## 2.2.3 ##

* Added support for capturing non-DBConnection errors in a Ecto Repo transaction. A store will throw either the changeset with the
error information or a JSON friendly error map when using a ! function. This new function either on a store or on `EctoSchemaStore`
will capture this instance and return a code friendly `{:error, Ecto.Changeset | Map}` instead of continuing to throw the error.

## 2.2.2 ##

* Added `validate_insert` and `validate_update` functions to a store module. These can be used to check changeset validation
before passing to actual insert or update functions.

## 2.2.0 ##

* Added `preconfigure` macro to stores to generate a quickly customized version of the insert and update functions.

## 2.1.1 ##

* Fixed `preload` option in `all` and `one` functional calls to allow any Ecto supported input like `preload_assocs`. These now invoke the same function.
* Added `order_preload_by` convienence function to create a sortable preload query. This function supports any input the Ecto Repo `order_by` function accepts.

```elixir
PersonStore.all [name: "Bob"], preload: [relation_field: PersonStore.order_preload_by(:id)]
```

## 2.1.0 ##

* Added support for `find_or_create` functions on a store.

## 2.0.0 ##

* Added support for `like` and `ilike` in the query builder. MySQL already does case insensitive and will not support `ilike`.
* Updated schema key listing utility to use built in Ecto `__schema__` reflection function. Will now filter out virtual types.
* Lexical Atom queries have been soft deprecated. There doesn't seem to be a reason to support this any further as that it does not provide much(if any) benefit over the standard query keyword list or map. This feature will be removed in a future release.
* Added `update_all` and `delete_all` functions to store.
* It has been a while since I last updated the Ecto dependency. It has now been updated to require 2.2 or greater. This has resulted in a major version revision since this will force applications to move up to a newer version of Ecto.

## 1.9.1 ##

* Added the ability to add a query to the front of an update statement. This will only update the first record retrieved and not all records.

## 1.9.0 ##

* Optimized query builder to utilize dynamic field names in Ecto queries. This will reduce compile time and generated beam size.

## 1.8.2 ##

* Order by was overwritting the entire query, fixed expression to build on previous query parameters.

## 1.8.1 ##

* Realized that including the module to support `rest_api_builder` directly in this library creates an unneccessary dependency which
also includes references to dependencies used by Phoenix and other frameworks. API provider moved to its own library. `rest_api_builder_essp`.

## 1.8.0 ##

* Adds more advanced event notifications through the EventQueues libary.
* Adds provider support when using the `rest_api_builder` library.

## 1.7.1 ##

* Added Parser for common changeset errors.

## 1.7.0 ##

* Added inserting of struct directly to all insert methods. This will bypass a changeset just as it does in Ecto.
* Added experimental update_all helper method. Use at your own risk, may not stay around.
* Update `one` function to use `Ecto.Repo.all` and to return the first record instead of throwing an error which `Ecto.Repo.one` will do.
It seems this is a more common use case than wanting an error to be thrown and break your application process.
* Added `order_by` options to `all` and `one` functions.
* Renamed `destructure` to `to_map` option and function based upon feedback. `destructure` still exists but points to `to_map`. Will be
removed in a future version.
* Changed `one` function receive a String id number as well as an integer. Making it more convient for when an id is passed via web params
or read from another text source. No need to convert it before passing it in.

## 1.6.0 ##

* Updated to add Ecto 2.1 support with the standard Elixir Date, Time, DateTime, NaiveDateTime structs.
* Fixed Elixir 1.4.0 warnings.
* Started changelog.
* Revised ex_docs with better structure.
