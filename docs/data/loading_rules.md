# Loading Rules

CumulusCI's data loader has many knobs and switches that you might want
to adjust during your load. It supports a ".load.yml" file format
which allows you to manipulate these load settings. The simplest way to
use this file format is to make a file in the same directory as your
recipe or dataset with a filename that is derived from the recipe's by replacing
everything after the first "." with ".load.yml". For example, if
your recipe is called "babka.recipe.yml" then your load file would be
"babka.load.yml". Similarly if you have a dataset called
`datasets/ds/ds.dataset.sql` then you could create `datasets/ds/ds.load.yml`.

Inside of that file you put a list of declarations in the following
format:

```yaml
- sf_object: Account
  api: bulk
  bulk_mode: parallel
```

Which would specifically load accounts using the bulk API's parallel
mode.

The specific keys that you can associate with an object are:

-   api: "smart", "rest" or "bulk"
-   batch_size: a number
-   bulk_mode: "serial" or "parallel"
-   load_after: the name of another sobject to wait for before loading

"api", "batch_size" and "bulk_mode" have the same meanings that
they do in mapping.yml as described in [API Selection](api-selection).

For example, one could force Accounts and Opportunities to load after
Contacts:

```yaml
- sf_object: Account
  load_after: Contact

- sf_object: Opportunity
  load_after: Contact
```

If you wish to share a loading file between multiple recipes or
datasets, you can refer to it with the `--loading_rules` option.
That will override the default filename (`<recipename>.load.yml`).
If you want both, or any combination of multiple files, you can do
that by listing them with commas between the filenames.
