[![Code Climate](https://codeclimate.com/github/pivotal-cf/docs-bookbinder.png)](https://codeclimate.com/github/pivotal-cf/bookbinder) [![Build Status](https://travis-ci.org/pivotal-cf/bookbinder.svg?branch=master)](https://travis-ci.org/pivotal-cf/bookbinder)
# Bookbinder

Bookbinder is a gem that binds together a unified documentation web application
from disparate source material.
Source material can be in markdown, HTML, or
[DITA](http://dita.xml.org/standard), and must be stored in local directories or
in git repositories.
Bookbinder runs [middleman](http://middlemanapp.com/) to produce a Rackup app
that you can deploy to Cloud Foundry.

**Note**: The Bookbinder gem is now known as `bookbindery`.
Please update your Gemfiles accordingly.

## Usage

Bookbinder is meant to be used from within a project called a **book**.
The book includes a configuration file that describes which documentation
repositories to use as source materials.
The bookbindery gem provides a set of scripts to aggregate those repositories
and publish them to various locations.
Bookbinder also provides scripts for running on a Continuous Integration system
that can detect when a documentation repository has been updated with new
content, and that can verify a composed book is free of any dead links.

## Installation

**Note**: Bookbinder requires Ruby version 2.0.0-p195 or higher.

To install the Bookbinder gem, add `gem "bookbindery"` to your Gemfile.
Creating a book is more involved process, but we plan to automate this process
in the near future.

### DITA-OT

Bookbinder uses the [DITA Open Toolkit](http://www.dita-ot.org/) (DITA-OT) to
process documents written in DITA.
If you have DITA sections in your book, you must install DITA-OT to process
them.

Once installed, specify the location of the DITA-OT library as an environment
variable named "PATH_TO_DITA_OT_LIBRARY".
We recommend that you use the full_easy_install type for the DITA-OT library.

**Note**: Ensure that the version of the DITA-OT library that you install
supports the DITA version in which your documents are written.

### Creating a book from scratch using local sections

Typically, the disparate source materials of your book are organized into
separate git repositories.

When writing documentation on your local machine, however, we recommend that you
add uncommitted changes to the preview web site that you serve on your machine.

The `bind local` command performs this operation by gathering local sections
from sibling directories of your book.
These sections' directories must have the same name as their remote git
repositories, but don't need to be git repositories for all commands.

The following is an annotated script that sets up a new book allowing 'bind
local' to run successfully.
This script names your book "mynewbook" and includes only one section,
[cloudfoundry/docs-dev-guide](https://github.com/cloudfoundry/docs-dev-guide).

    mkdir mynewbook
    cd mynewbook

    # Create a Gemfile
    bundle init

    # Add the bookbindery gem to it
    echo 'gem "bookbindery"' >> Gemfile

    # Install gems listed in the Gemfile, creating a bin/ dir for executables
    bundle install --binstubs

    # Create a minimal configuration file
    cat > config.yml <<YAML
    book_repo: myorg/myrepo
    public_host: localhost:9292
    sections:
    - repository:
        name: cloudfoundry/docs-dev-guide
      directory: my/included-section
    YAML

    # Create a directory required by Middleman
    mkdir -p master_middleman/build

    # Clone the section in the config.yml so it can be included in
    # the final site
    git clone https://github.com/cloudfoundry/docs-dev-guide ../docs-dev-guide

    # Run the bind local command, which pulls in the section from
    # the directory cloned above
    bin/bookbinder bind local

    # Start up the web site locally
    cd final_app
    bundle
    rackup

After running the script, you can visit your book at
[localhost:9292/my/included-section](http://localhost:9292/my/included-section)
and see the section that was brought in. Browsing to the [home page](http://localhost:9292/) currently returns a 404 because we did not inlcude
anything inside the `master_middleman/source/` directory.

You can skip ahead for [more information on the bind command](#bind-command).

### Deploying your book
- Create an AWS bucket for green builds and put info into `credentials.yml`
- Set up CF spaces for staging and production and put details into `credentials.yml`
- Deploy to production
- (Optional) Register your sitemap with Google Webmaster Tools

### A more exhaustive config.yml example

```YAML
book_repo: org-name/repo-name
cred_repo: org-name/private-repo
layout_repo: org-name/master-middleman-repo

sections:
  - repository:
      name: org-name/bird-repo
      ref: 165c28e967d58e6ff23a882689c953954a7b588d
    directory: birds
    subnav_template: cool-sidebar-partial		# optional
  - repository:
      name: org-name/reptile-repo
      ref: d07101dec08a698932ef0aa2fc36316d6f7c4851
    directory: reptiles

archive_menu:						# optional
  - v1.3.0.0
  - v1.2.0.0: archive-repo/your_pdf.yml

public_host: animals.example.com
template_variables:					# optional
  var_name: special-value
  other_var: 12

```

Assuming your book is in git, your `.gitignore` should contain the following
entries, which are directories generated by Bookbinder:

    output
    final_app

`master_middleman` is a directory which forms the basis of your site. [Middleman](http://middlemanapp.com/) configuration and top-level assets, javascripts, and stylesheets should all be placed in here. You can also have ERB layout files. Each time a bind operation is run, this directory is copied to `output/master_middleman`. Then each section repo is copied (as a directory) into `output/master_middleman/source/`, before middleman is run to generate the final app.

`.ruby-version` is used by [Ruby version managers](https://www.ruby-toolbox.com/categories/ruby_version_management) to select the appropriate Ruby version for a given project.

### Credentials Repository

The credentials repository should be a private repository, referenced in your `config.yml` as `cred_repo`. It contains `credentials.yml`, which must include your deployment credentials:

```YAML
aws:
  access_key: AKIAIOSFODNN7EXAMPLE
  secret_key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY
  green_builds_bucket: s3_bucket_name
cloud_foundry:
  username: sam
  password: pel
  api_endpoint: https://api.run.pivotal.io
  organization: documentation-team
  app_name: docs
  staging_space: docs-staging
  production_space: docs-production
  staging_host:
    cfapps.io:
      - staging-route-subdomain
      - another-staging-route-subdomain
  production_host:
    cfapps.io:
      - production-route-subdomain
```

### Layout Repository

If you specify a `layout_repo:` in `config.yml` with the full name of a git repository (e.g., `cloudfoundry/my-doc-layout`, which will default to GitHub), it will be downloaded for use as your book's `master_middleman` directory.

### Section Repository Ref

By default, the `bookbinder bind remote` command binds the most current versions (i.e., the `master` branch) of the documents in the git repositories specified by the `sections:` of your `config.yml`.

Bookbinder supports a `ref` key to enable use of an alternate version of a repo. The value of this key can be the name of a branch (e.g., `develop`), a SHA, or a tag (`v19`).

```
sections:
  - repository:
      name: org-name/bird-repo
      ref: my-branch
```

Example SHA:

```
sections:
  - repository:
      name: org-name/bird-repo
      ref: 165c28e967d58e6ff23a882689c953954a7b588d
```

**Note**: Bookbinder only uses the <code>ref</code> key when binding 'remote'. The <code>bookbinder bind local</code> command ignores the <code>ref</code> key.



## Supported Formats

* [Markdown](#user-content-markdown)
* [DITA](#user-content-dita)

### Markdown
All markdown sections must be specified within the section key of the `config.yml`.

### DITA

Specify the following in the `config.yml`:

* All DITA sections within the dita_sections key of the `config.yml`
* In the first DITA section listed in the `config.yml`, a key-value pair "ditamap_location: my-ditamap.ditamap"
* (optional) In the first DITA section listed in the `config.yml`, a key-value pair "ditaval_location: my-ditaval.ditaval"

For example:


```YAML
dita_sections:

  - repository:
      name: org-name/bird-repo
      ref: 165c28e967d58e6ff23a882689c953954a7b588d                #optional
    directory: birds
    ditamap_location: path/to/my-special-ditamap-location.ditamap
    ditaval_location: path/to/my-special-ditaval-location.ditaval  #optional

 - repository:
 	 name: org-name/dependent-section
 	 ref: 165c28e967d58e6ff23a882689c123998a7b577e                 #optional
   directory: dependent-section

```

**Note**: You'll need to have properly installed and specified the [DITA-OT](#user-content-dita-ot) library.

## Middleman Templating Helpers

Bookbinder comes with a Middleman configuration that provides a handful of helpful functions, and should work for most book projects. To use a custom Middleman configuration instead, place a `config.rb` file in the `master_middleman` directory of the book project. This will overwrite Bookbinder's `config.rb`.

Bookbinder provides several helper functions that can be called from within an .erb file in a doc repo, such as a layout file.

### Quick Links
`<%= quick_links %>` produces a table of contents based on in-page anchors.

### Breadcrumbs
`<%= breadcrumbs %>` generates a series of breadcrumbs as a UL HTML tag. The breadcrumbs go up to the site's top-level, based on the title of each page. The bottom-most entry in the list of breadcrumbs represents the current page; the rest of the breadcrumbs show the hiearchy of directories that the page lives in. Each breadcrumb above the current page is generated by looking at the [frontmatter](http://middlemanapp.com/basics/frontmatter/) title of the index template of that directory. If you'd like to use breadcrumb text that is different than the title, an optional 'breadcrumb' attribute can be used in the frontmatter section to override the title.

### Subnavs
`<%= yield_for_subnav %>` inserts the appropriate template in /subnavs, based on each constituent repositories' `subnav_template:` parameter in `config.yml`. The default template (`\_default.erb`) uses the label `default` and is applied to all sections unless another template is specified with subnav\_template. Template labels are the name of the template file with extensions removed. ("sample" for a template named "sample.erb")

If your book includes a dita_section, instead of providing a subnav_template, Bookbinder will look for a file `_dita_subnav_template.erb` from `master_middleman/source/subnavs`.

Optionally, Bookbinder will make available subnav links in a json format at `/subnavs/dita-subnav-props.json`. They could be consumed with a javascript library (e.g. React.js) to create your subnav. Bookbinder will have written the name of the file containing the links (`dita-subnav-props.json`) from _dita_subnav_template.erb at a data attribute called data-props-location on 'div.nav-content'.

An example of the json links:

```code
{
  "links":
  [
    {"url": "/dita-section-one/some-guide.html", "text": "my topic 1"},
    {"url": "/dita-section-one/../dita-section-dependency/some-guide-1.html", "text": "my topic dependency"}
  ]
}
```

### Code Snippets
`<%= yield_for_code_snippet from: 'my-org/code-repo', at: 'myCodeSnippetA' %>` inserts code snippets extracted from code repositories.

To delimit where a code snippet begins and ends, you must use the format of `code_snippet MARKER_OF_YOUR_CHOOSING start OPTIONAL_LANGUAGE`, followed by the code, and then finished with `code_snippet MARKER_OF_YOUR_CHOOSING end`:
If the `OPTIONAL_LANGUAGE` is omitted, your snippet will still be formatted as code but will not have any syntax highlighting.

Code snippet example:

```clojure

; code_snippet myCodeSnippetA start clojure
	(def fib-seq
   	  (lazy-cat [0 1] (map + (rest fib-seq) fib-seq)))
	user> (take 20 fib-seq)
	(0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610 987 1597 2584 4181)
; code_snippet myCodeSnippetA end

```

### Archive Menu

Bookbinder allows you to specify a drop-down menu template for use in the navbar. This can contain links to PDFs or other archived versions of documentation. To specify a dropdown menu, add the `archive_menu` key in `config.yml` as follows:

```
  archive_menu:
    - v1.3.0.0
    - v1.2.0.0: my-pdf-repo/v1.2.0.0.pdf
```

The first key (e.g. v1.3.0.0) is available for use as a title in your navbar. You can configure the structure of the drop-down menu by creating a template in `master_middleman/source/archive_menus/_default.erb`.

Finally, to insert the archive menu, use the `<%= yield_for_archive_drop_down_menu %>` tag in the appropriate part of the navbar in your layout.erb. 

### Including Assets

Bookbinder also includes helper code to correctly find image, stylesheet, and javascript assets. When using `<% image_tag ...`, `<% stylesheet_link_tag ...`, or `<% javascript_include_tag ...` to include assets, Bookbinder will search the entire directory structure starting at the top-level until it finds an asset with the provided name. For example, when resolving `<% image_tag 'great_dane.png' %>` called from the page `dogs/big_dogs/index.html.md.erb`, Middleman will first look in `images/great_dane.png.` If that file does not exist, it will try `dogs/images/great_dane.png`, then `dogs/big_dogs/images/great_dane.png`.

## Commands

Bookbinder's entry point is the `bookbinder` executable. It should be invoked from the book directory. The following commands are available:

### `bind` command

Bookbinder's most important command is `bind`. It takes one argument on the command line: `local` or `remote`.

        bin/bookbinder bind local

will find documentation repositories in directories that are siblings to your current directory.

        bin/bookbinder bind remote

will find doc repos by downloading the latest version from git. Note that if any of the repositories configured as 'sections' are private, you should [create an SSH key](https://help.github.com/articles/generating-ssh-keys/) for Bookbinder from an account that has access to the section repositories.

You should `ssh-add` this key to give Bookbinder access to the repositories.

The bind command creates two output directories, one named `output/` and one named `final_app/`. These are placed in the current directory and are overwritten each time you run Bookbinder.

**Note**: When Bookbinder binds DITA sections of your book, it only sends error messages to the screen. Use the `--verbose` option with `bind` to see the non-filter output.

#### The `final_app` directory

`final_app/` contains Bookbinder's ultimate output: a Rack web-app that can be pushed to Cloud Foundry or run locally.

The Rack web-app will respect redirect rules specified in `redirects.rb`, so long as they conform to the `rack/rewrite` [syntax](https://github.com/jtrupiano/rack-rewrite). For example:

```ruby
rewrite   '/wiki/John_Trupiano',  '/john'
r301      '/wiki/Yair_Flicker',   '/yair'
r302      '/wiki/Greg_Jastrab',   '/greg'
r301      %r{/wiki/(\w+)_\w+},    '/$1'
```

#### The `output` directory

`output/` contains an intermediary state. This includes `output/master_middleman`, the final prepared directory that the `bind` script ran middleman against.

**Note**: As of version 0.2.0, the `bind` command no longer generates PDFs.

### `update_local_doc_repos` command

As a convenience, Bookbinder provides a command to update all your local doc repos, performing a git pull on each one:

        bin/bookbinder update_local_doc_repos

### `tag` command

The `bookbinder tag` command commits Git tags to checkpoint a book and its constituent document repositories. This allows the tagged version of the documentation to be re-generated at a later time.

        bin/bookbinder tag book-formerly-known-as-v1.0.1

## Running the App Locally

    cd final_app
    bundle
    rackup

This will start a [rack](http://rack.github.io) server to serve your
documentation website locally at
[http://localhost:9292/](http://localhost:9292/). While making edits in
documentation repos, we recommend leaving this running in a dedicated shell
window. It can be terminated by hitting `ctrl-c`.

## Continuous Integration

### CI for books

The currently recommended tool for CI with Bookbinder is [GoCD](http://www.go.cd).

#### CI Runner
You will want a build that executes this shell command:

        bundle install --binstubs
        bin/bookbinder run_publish_ci

This will bind a book and push it to staging.

## Deploying

Bookbinder has the ability to deploy the finished product to either staging or production. The deployment scripts use the gem's pre-packaged CloudFoundry Go CLI binary (separate versions for darwin-amd64 and linux-amd64 are included); any pre-installed version of the CLI on your system will **not** be used.

### Setting up CF Apps

Each book should have a dedicated CF space and host for its staging and production servers.
The Cloud Foundry organization and spaces must be created manually and specified as values for "organization", "staging_space" and "production_space" in `config.yml`.
Upon the first and second deploy, bookbinder will create two apps in the space to which it is deploying. The apps will be named `"app_name"-blue` and `"app_name"-green`.  These will be used for a [blue-green deployment](http://martinfowler.com/bliki/BlueGreenDeployment.html) scheme.  Upon successful deploy, the subdomain of `cfapps.io` specified by "staging_host" or "production_host" will point to the most recently deployed of these two apps.


### Deploy to Staging
Deploying to staging is not normally something a human needs to do: the book's CI script does this automatically every time a build passes.

The following command will deploy the build in your local 'final_app' directory to staging:

        bin/bookbinder push_local_to_staging

### Deploy to Production
Deploying to prod is always done manually. It can be done from any machine with the book project checked out, but does not depend on the results from a local bind (or the contents of your `final_app` directory). Instead, it pulls the latest green build from S3, untars it locally, and then pushes it up to prod:

        bin/bookbinder push_to_prod <build_number>

If the build_number argument is left out, the latest green build will be deployed to production.

## Generating a Sitemap for Google Search Indexing

The sitemap file `/sitemap.xml` is automatically regenerated when binding. When setting up a new docs website, make sure to add this sitemap's url in Google Webmaster Tools (for better reindexing?).

## Contributing to Bookbinder

### Running Tests

To run bookbinder's rspec suite, install binstubs, then run the included rake task:

Once: `bundle install --binstubs`

Then at any time: `bin/rake`
