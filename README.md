[![Code Climate](https://codeclimate.com/github/pivotal-cf/docs-bookbinder.png)](https://codeclimate.com/github/pivotal-cf/bookbinder) [![Build Status](https://pubtools.ci.cf-app.com/pipelines/pubtools/jobs/bookbinder/badge)](https://pubtools.ci.cf-app.com/pipelines/pubtools/jobs/bookbinder)

# Bookbinder / Bookbindery

This is the repository for 'bookbinder' and 'bookbindery' gems. On 2015/01/07 the 'bookbinder' gem was renamed to 'bookbindery' gem.

**Note**: This GitHub repository is no longer supported.

To use the Bookbindery gem, include the following in your book's Gemfile:

```
source 'https://rubygems.org'
gem 'bookbindery'
```

Bookbinder is a gem that binds together a unified documentation web application
from disparate source material.
Source material can be in markdown, HTML, or
[DITA](http://dita.xml.org/standard), and must be stored in local directories or
in git repositories.
Bookbinder runs [middleman](http://middlemanapp.com/) to produce a Rack app
that you can deploy to Cloud Foundry.

See the [Bookbinder wiki](https://github.com/pivotal-cf/bookbinder/wiki) for detailed information and instructions, such as how to configure [credentials for multiple git services](https://github.com/pivotal-cf/bookbinder/wiki/Credentials-for-multiple-git-services).

## <a id='install-ditaot'></a>Installation

**Note**: Bookbinder requires Ruby version 2.0.0-p195 or higher.

Follow the instructions below to install Bookbinder:

1. Add `gem "bookbindery"` to your Gemfile.
1. Run `bundle install` to install the dependencies specified in your Gemfile.

1. (**Optional**) Install the [DITA Open Toolkit](http://www.dita-ot.org/)
    (DITA-OT).

    Bookbinder uses the [DITA Open Toolkit](http://www.dita-ot.org/) (DITA-OT)
    to process documents written in DITA.
    If you have DITA sections in your book, you must install DITA-OT to process
    them.

    Once installed, specify the location of the DITA-OT library as an
    environment variable named **PATH_TO_DITA_OT_LIBRARY**.

    We recommend that you use the `full_easy_install` type for the DITA-OT
    library.

    **Note**: Ensure that the version of the DITA-OT library that you install
    supports the DITA version in which your documents are written.


### Install on Mac OS

1. Install Ruby and needed dependencies

    ```
    gem install bundler
    brew install ant
    ```

1. Install Dita-OT, version 1.7.5, full easy from http://www.dita-ot.org/download 

    ```
    cat >> ~/.bash_profile << EOF
    export PATH_TO_DITA_OT_LIBRARY="/Users/pivotal/workspace/DITA-OT1.7.5"
    EOF
    export PATH_TO_DITA_OT_LIBRARY="/Users/pivotal/workspace/DITA-OT1.7.5"
    ```

1. Build the book and view it

    ```
    bundle exec bookbinder bind local

   cd final_app/
   rackup
   ```

## Usage

Bookbinder is intended to be used from within a project called a **book**.
The book includes a configuration file. the `config.yml`, that describes which documentation repositories to use as 
source materials.

The **bookbindery** gem provides a set of scripts to aggregate those repositories
and publish them to various locations.

Bookbinder also provides scripts for running on a Continuous Integration system that can detect when a documentation 
repository has been updated with newcontent, and that can verify a composed book is free of any dead links.

1. To create a new book on your local machine, run `bookbinder generate
    BOOKNAME`, replacing BOOKNAME with the name of your book. For example:

    ```
    bundle exec bookbinder generate cloud-documentation
    ```

    The `bookbinder generate BOOKNAME` command creates a directory named
    `BOOKNAME`.
    This directory contains the following:
    * A Gemfile referencing the `bookbindery` gem
    * A minimal `config.yml` file
    * A `bin` directory containing code
    * A `master_middleman/source` directory containing an index page
    * An empty `master_middleman/build/` directory

1. After running `bookbinder generate`, run `bookbinder bind local` to assemble
    your book from the repositories specified in the `config.yml` file.

    **Note**: At this point, unless you've added anything to the `config.yml`,
    the `config.yml` contains no references to any repositories, and so bookbinder will
    bind a book with no content.

1. Run the following commands to start up the web site locally:
    * `cd final_app`
    * `rackup`

1. Launch a web browser to `http://localhost:9292/` to view your book.

As typically used, the disparate source materials of a book are organized into separate git repositories.

When writing documentation on your local machine, however, we recommend that you
add uncommitted changes to the preview web site that you serve on your machine.

The `bind local` command performs this operation by gathering local sections from sibling directories of your book.
These sections' directories must have the same name as their remote git repositories, but don't need to be git repositories 
for all commands.

### Adding Basic Auth to Your Served Book

You can optionally require a username and password to access any book served by running `rackup` in `final_app` by setting 
the following environment variables:

* 	`export SITE_AUTH_USERNAME=<your-book-username>`
*	`export SITE_AUTH_PASSWORD=<your-book-password>`

If these environment variables are not set, basic auth is not enabled.

### Deploying Your Book
- Create an AWS bucket for green builds and put info into `credentials.yml`
- Set up CF spaces for staging and production and put details into `credentials.yml`
- Deploy to production
- (Optional) Register your sitemap with Google Webmaster Tools

### A More Exhaustive config.yml Example

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
    product_id: my_product  			        # optional

products:										# optional
  - id: my_product
    subnav_root: reptiles/index

archive_menu:									# optional
  - v1.3.0.0
  - v1.2.0.0: archive-repo/your_pdf.yml

public_host: animals.example.com

template_variables:								# optional
  var_name: special-value
  other_var: 12

```

Assuming your book is in git, your `.gitignore` should contain the following
entries, which are directories generated by Bookbinder:

    output
    final_app

`master_middleman` is a directory which forms the basis of your site. [Middleman](http://middlemanapp.com/) configuration and top-level assets, javascripts, and stylesheets should all be placed in here. You can also have ERB layout files. Each time a bind operation is run, this directory is copied to `output/master_middleman`. Then each section repository is copied (as a directory) into `output/master_middleman/source/`, before middleman is run to generate the final app.

`.ruby-version` is used by [Ruby version managers](https://www.ruby-toolbox.com/categories/ruby_version_management) to select the appropriate Ruby version for a given project.

### Using Multiple Configuration Files

Bookbinder now supports breaking the above config.yml across multiple files.

A non-empty config.yml is still required in the book's root directory, however you may optionally include any number of valid yaml files with config in a directory named `config`, which you will need to create. At runtime, configuration will be loaded from `config.yml` and any files matching `*.yml` in the `config` directory.

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
  env:
    staging:
      space: docs-staging
      host:
        cfapps.io:
        - staging-route-subdomain
        - another-staging-route-subdomain
    production:
      space: docs-production
      host:
        cfapps.io:
        - production-route-subdomain
```

### Layout Repository

If you specify a `layout_repo:` in `config.yml` with the full name of a git repository (e.g., `cloudfoundry/my-doc-layout`, which will default to GitHub), it will be downloaded for use as your book's `master_middleman` directory.

Any files included in your book's `master_middleman/source` directory will override files of the same name in the specified layout repository.

### Specifying Repository Refs

By default, the `bookbinder bind remote` command binds the most current versions (i.e., the `master` branch) of the documents in the git repositories specified by the `sections:` of your `config.yml`.

#### Section Repository Ref

Bookbinder supports a `ref` key to enable use of an alternate version of a repository. The value of this key can be the name of a branch (e.g., `develop`), a SHA, or a tag (`v19`).

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

#### Layout Repository Ref

Bookbinder supports a `layout_repo_ref` key to enable use of an alternate version of a layout repository. The value of this key can be the name of a branch (e.g., `develop`), a SHA, or a tag (`v19`).

```
layout_repo: cloudfoundry/my-doc-layout
layout_repo_ref: v19
```

**Note**: Bookbinder only uses the <code>ref</code> key when binding 'remote'. The <code>bookbinder bind local</code> command ignores the <code>ref</code> key.

### Specifying a Path in Repository for Section

You can optionally specify a directory inside a source repository to use as a section with the `at_path` key, as follows:

```
sections:
  - repository:
      name: org-name/bird-repo
      at_path: scrub/jay
    directory: birds
    subnav_template: cool-sidebar-partial
```

In the above example, the contents of the `bird-repo/scrub/jay` directory would be made available at `birds` on your bound book.

## Supported Formats

* [Markdown](#user-content-markdown)
* [DITA](#user-content-dita)

### Markdown
All markdown sections must be specified within the section key of the `config.yml`.

#### YAML Front Matter

Bookbinder supports YAML [frontmatter](https://middlemanapp.com/basics/frontmatter/). Frontmatter (or "front matter") allows you to include page-specific variables in YAML format at the top of a markdown file.

If you want to include front matter in a markdown file, create a block at the top of the file by adding two lines of triple hyphens: `---`. Inside this block, you can create new data accessible to Bookbinder using the `current_page.data` hash. For example, if you add `title: "My Title"`, Bookbinder can access `current_page.data.title` to read "My Title".

Bookbinder currently supports the following front matter when binding books:

  - `title:` Specifies the title of HTML page.
  - `owner:` Specifies the owner of a topic. This can be a single owner, or multiple owners.

Example of front matter for a topic with one owner:

```
---
title: Understanding Cloud Foundry
owner: Cloud Foundry Concepts Team
---
```
    
Example of front matter for a topic with three owners:

```
---
title: Using Cloud Foundry Services with the CLI
owner:
  - Services Team
  - Command Line Interface Team
  - Documentation Team
---
```

### DITA

Specify the following in the `config.yml`:

* All DITA sections within the dita_sections key of the `config.yml`
* In either the first or in each (for multiple ditamaps) DITA section listed in the `config.yml`, a key-value pair "ditamap_location: my-ditamap.ditamap"
* (optional) In either the first or in each (for multiple ditamaps) DITA section listed in the `config.yml`, a key-value pair "ditaval_location: my-ditaval.ditaval"

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
      ditamap_location: path/to/other-ditamap.ditamap
      ditaval_location: path/to/other-ditamap.ditaval                 #optional
```

**Note**: You'll need to have properly installed and specified the [DITA-OT](#user-content-dita-ot) library.

#### DITA Dependent Sections

If a `dita_section` requires support DITA files from another repository, you can specify the support repository beneath a `dependent_sections` key in the parent repository.

Dependent sections are cloned into the parent section's directory. In the following example, the content from the dependent section will be available at `<your-domain>/birds/dinosaurs/`.

```
dita_sections:
  - repository:
      name: org-name/bird-repo
      ref: 165c28e967d58e6ff23a882689c953954a7b588d
    directory: birds
    ditamap_location: path/to/my-special-ditamap-location.ditamap
    ditaval_location: path/to/my-special-ditaval-location.ditaval
    dependent_sections:
    - repository:
        name: org-name/dinosaur-repo
        ref: pterodactyl
      directory: dinosaurs
```

#### ERB Support

Bookbinder supports ERB tags if they are specified as unicode: `<%=` is `&lt;%=` and `%>` is `%&gt;`. This enables use of [helper functions](#middleman-templating-helpers).

If you want to render ERB tags as text and not evaluated as code by the Ruby interpreter, you must escape the opening ERB tag with a backslash as follows: `&lt;%=` is escaped as `&lt;\%=`. This functionality is useful for code examples, for instance.


## Source Repository Link

Render a link with the URL of the current page's source repository and the text 'View the source for this page in GitHub'.

In `config.yml`, add:

```
repo_link_enabled: true
```

**Note**: This feature renders a link to a file with either the extension `.html.md.erb` for Markdown source files, or the extension `.xml` for DITA source files. Ensure that all of your files have appropriate extensions.

For this helper to render the link, you must pass the helper a whitelist of the environments where you want the link to display.

For example, suppose you have an application with staging and production environments available at 'example-staging.cfapps.io' and 'example-production.cfapps.io', and you only want this link to display in the staging environment. Whitelist staging as an included environment as illustrated in the [section below](#including-source-repository-link).

### Including source repository link

You can add the source repository link to the `source/layouts/layout.erb` file in the master_middleman directory or in the layout repository, or to the bottom of an individual page. For example, you can add the line `<%= render_repo_link(include_environments: ['staging']) %>` in the desired location for your link to include the link only on sites with 'staging' in their URLs.

If you include the line below in your `source/layouts/layout.erb`, the source repository partial will be rendered on every page of your book that has not been specifically excluded:

```
<%= render_repo_link(include_environments: [<your-environments]) %>
```

To specifically exclude the repository link from being rendered on a page, add the line `<% exclude_repo_link %>` to the desired page.

### Product Name Variables

For flexibility, the product name (a long version and a short one) and version are defined as variables. Here's how to use them:

**Define these three variables in `config.yml`:**

```
template_variables:
  - product_name_long: Apache Geode
  - product_name: Geode
  - product_version: 1.2

```

**Use the following Ruby syntax to refer to these variables everywhere _except_ in `title:` lines:**

    <%=vars.product_name %>
    <%=vars.product_name_long %>
    <%=vars.product_version %>
    
**You can't use these variables in `title:` lines. Here's the workaround:**

Instead of:

    ---
    title: Apache Geode 1.2 Documentation
    ---
    
Do this:

    <% set_title(product_name_long, product_version, "Documentation") %>

Why? Because the `title:` construct is not Ruby code, it's YAML, and it cannot interpret Ruby variables.

**Cautions:**

  - Begin with `<%`, not `<%=`. (We're invoking a function, not printing its value.)
  - Do not put a space before the opening parenthesis (use `set_title()` not `set_title ()`.)
  - **Do not** quote the three product variable names (`product_name`, `product_name_long`, and `product_version`). **Do** quote all other text.

## Page Styles

You can add CSS styles directly to a page using traditional `<style>` tags directly below the page frontmatter (immediately before the page content).

    ---
    title: A Christmas Carol, Stave One
    ---

    <style>
        h1.unusual {
            font-size: x-small;
        }
    </style>

    Your text here.


## Feedback Form

Render a feedback form on your book's pages.

### Creating a feedback endpoint

In `config.yml`, add:

```
feedback_enabled: true
```

When feedback is enabled in this way, a POST endpoint is created at `/api/feedback` on your server, which will send a formatted email via the SendGrid Mail API. Accepted parameters for the post include: `date`, `page_url`, `comments`, and `is_helpful`.

Required credentials will need to be set in your environment for the feature to send mail. These include: `SENDGRID_USERNAME`, `SENDGRID_API_KEY`, `FEEDBACK_TO`, `FEEDBACK_FROM`.

### Including feedback partial

1. In the master_middleman dir or the layout repository `source/layouts/layout.erb` file, or on an individual page where you want the feedback form, add `<%= yield_for_feedback %>`. If you include `<%= yield_for_feedback %>` in your `source/layouts/layout.erb`, the feedback partial will be rendered on every page of your book.

1. Create a partial named `_feedback.erb` that is your feedback form, and any JavaScript required to send a valid POST to the endpoint configured above.

#### Excluding feedback partial on specified pages

You can choose to not have the feedback form render on specified pages if you add the following line `<%= exclude_feedback %>` above `<%= yield_for_feedback %>`.

Use this functionality if you included `<%= yield_for_feedback %>` in your `source/layouts/layout.erb` and want to exclude the partial from certain pages.

## Middleman Templating Helpers

Bookbinder comes with a Middleman configuration that provides a handful of helpful functions, and should work for most book projects. To use a custom Middleman configuration instead, place a `config.rb` file in the `master_middleman` directory of the book project. This will overwrite Bookbinder's `config.rb`.

Bookbinder provides several helper functions that can be called from within an `.erb` file in a doc repository, such as a layout file.

### Quick Links
`<%= quick_links %>` produces a table of contents based on in-page anchors.

### Modified Date
`<%= modified_date %>` displays the most recent commit date for the file in the format 'Page last updated: September 1, 2015'. You can provide an optional date format, i.e. `<%= modified_date '%m/%d/%y'%>`.

The `modified_date` helper uses the date of the most recent commit that does not contain the text "[exclude]" in its commit message.

### Diagram (using [Mermaid](https://github.com/knsv/mermaid))

The `mermaid_diagram` helper accepts a block including text formatted to generate [Mermaid diagrams](https://mermaidjs.github.io/). In order to use this helper, include [the Mermaid package](https://mermaidjs.github.io/usage.html#installation) in your book.

```
<% mermaid_diagram do%>
 graph TB
         subgraph one
         a1-->a2
         end
         subgraph two
         b1-->b2
         end
         subgraph three
         c1-->c2
         end
         c1-->a2
<% end %>
```

### Breadcrumbs
`<%= breadcrumbs %>` generates a series of breadcrumbs as a UL HTML tag. The breadcrumbs go up to the site's top-level, based on the title of each page. The bottom-most entry in the list of breadcrumbs represents the current page; the rest of the breadcrumbs show the hierarchy of directories that the page lives in. Each breadcrumb above the current page is generated by looking at the [frontmatter](http://middlemanapp.com/basics/frontmatter/) title of the index template of that directory. If you'd like to use breadcrumb text that is different than the title, an optional 'breadcrumb' attribute can be used in the frontmatter section to override the title.

### Subnavs
`<%= yield_for_subnav %>` inserts the appropriate subnav based on each constituent repositories' `subnav_template:` or `product_id:` parameter in `config.yml`. For a given section, only one key should be used. If both keys are specified, bookbinder will default to using the subnav_template.

The default template (`\_default.erb`) uses the label `default` and is applied to all sections unless another template is specified with subnav\_template or subnav\_name. Template labels are the name of the template file with extensions removed. ("sample" for a template named "sample.erb")

#### Subnavs for DITA

If your book includes a dita_section, Bookbinder will automatically look for a file `subnav_template.erb` from `master_middleman/source/subnavs`. No additional keys are necessary in your `config.yml`.

Bookbinder makes subnav links available in a JSON format at `/subnavs/dita_subnav_<your-dita-section-directory>-props.json`. They could be consumed with a JavaScript library (e.g. React.js) to create your subnav. Bookbinder will have written the name of the file containing the links from `subnav_template.erb` at a data attribute called data-props-location on 'div.nav-content'.

An example of the JSON links:

```code
{
  "links":
  [
    {"url": "/dita-section-one/some-guide.html", "text": "my topic 1"},
    {"url": "/dita-section-one/../dita-section-dependency/some-guide-1.html", "text": "my topic dependency"}
  ]
}
```

**Note:** Use of `_dita_subnav_template.erb` is deprecated as of Bookbindery 7.2.0. If your DITA subnavs currently rely on this file, simply rename it to `subnav_template.erb` in the same location.

#### Subnav from Template (subnav_template):
If specified for a section, Bookbinder will look for a file of name <subnav-template>.erb in `master_middleman/source/subnavs` and insert this partial into the template at the code helper.

```YAML
sections:
  - repository:
      name: org-name/bird-repo
    directory: birds
    subnav_template: subnav-about-birds
```

#### Subnav from Config (product_id):
Specifying `subnav_root` under the `products` key and associating this to a section via `product_id` generates navigation-related json by parsing the HTML file specified by `subnav_root` for any linked H2s and spidering to those linked pages to make a subnav tree. This json can then be consumed with a javascript library (e.g. React.js) to create your subnav.

This feature not currently supported for DITA, though the `subnav_template` key does something very similar when used in dita_sections (see above).

**Requirements:**

* In `config.yml`: a `product_id` key for each section to display the generated subnav, and a `products` section that defines each `product_id` (as key `id`) used for those sections.
* Properly formatted page for each `subnav_root`

```yaml
sections:
  - repository:
      name: org-name/bird-repo
    directory: birds
    product_id: my_product
  - repository:
      name: org-name/reptile-repo
    directory: reptiles
    product_id: my_product

products:
  - id: my_product
    subnav_root: reptiles/index
```

**Keys:**

* `id`: Links a given section to its product in the config. Should contain no spaces.
* `subnav_root`: Root file to be parsed for to-be-generated subnavs.

**Example subnav_root:**

To generate a subnav, `bookbinder` starts spidering from the `subnav_root`, following `a` elements with the `subnav` class. This creates a JSON file with the subnav contents, described in more detail below.

`reptiles/index.html.md`:

```markdown
<a href="./thing-one.html" class="subnav">My First Nav Item</a>

Some text that won't be in the Nav

## <a href="./thing-two.html" class="subnav">My Second Nav Item</a>
```

Note that the links can be anywhere on the page (the second link is in an `h2`, for instance), but will be followed in order.

`reptiles/thing-one.html`:

```markdown

- <a href="./nested-thing.html" class="subnav">My Nested Nav Item</a>

```

`reptiles/thing-two.html`:

```markdown
## Won't Show Up in the Nav
Nothing to see here.
```

`reptiles/nested-thing.html`:

```markdown
## End of the line

No more.
```


### Code Snippets
`<%= yield_for_code_snippet from: 'my-org/code-repo', at: 'myCodeSnippetA' %>` inserts code snippets extracted from code repositories.

To delimit where a code snippet begins and ends, you must use the format of 
`code_snippet MARKER_OF_YOUR_CHOOSING start OPTIONAL_LANGUAGE`, followed by the code, and then finishing with 
`code_snippet MARKER_OF_YOUR_CHOOSING end`.
If you omit the `OPTIONAL_LANGUAGE`, your snippet will still be formatted as code but will not have any syntax highlighting.

Code snippet example:

```clojure

; code_snippet myCodeSnippetA start clojure
	(def fib-seq
   	  (lazy-cat [0 1] (map + (rest fib-seq) fib-seq)))
	user> (take 20 fib-seq)
	(0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610 987 1597 2584 4181)
; code_snippet myCodeSnippetA end

```

To insert a code snippet from a GitHub repository, you must add the repository as a **dependent section** resource in the 
`config.yml` of the book. The `dependent section` in the `config.yml` must end with a `no-docs: true` statement.

Example excerpt from a `config.yml`:

```
- repository:
    name: cloudfoundry/docs-buildpacks
  directory: buildpacks
  dependent_sections:
  - repository:
      name: cloudfoundry-samples/pong_matcher_grails
  - repository:
      name: cloudfoundry-samples/pong_matcher_groovy
  - repository:
      name: cloudfoundry-samples/pong_matcher_spring
  - repository:
      name: cloudfoundry-samples/pong_matcher_ruby
    no-docs: true
```

The above YAML adds four GitHub repositories as "dependent sections" to `docs-buildpacks` in the `docs-book-cloudfoundry` book. These are the repositories referenced by the `yield_for_code_snippet` in the buildpack topics. 

### Archive Menu

Bookbinder allows you to specify a drop-down menu template for use in the navbar. This can contain links to PDFs or other archived versions of documentation. To specify a drop-down menu, add the `archive_menu` key in `config.yml` as follows:

```
  archive_menu:
    - v1.3.0.0
    - v1.2.0.0: my-pdf-repo/v1.2.0.0.pdf
```

The first key (e.g. v1.3.0.0) is available for use as a title in your navbar. You can configure the structure of the drop-down menu by creating a template in `master_middleman/source/archive_menus/_default.erb`.

Finally, to insert the archive menu, use the `<%= yield_for_archive_drop_down_menu %>` tag in the appropriate part of the navbar in your layout.erb.

### Template Variables

Bookbinder allows you to define **template variables** by adding key-value pairs to the `config.yml` file for your book.

To use a template variable, add the key to a source file.
When you then bind your book, Bookbinder replaces the key with the value defined in the `config.yml` file.

* To define a new template variable, add the key-value pair to the **template_variables** section of the  `config.yml` file.

    Example `config.yml` file excerpt:

    <pre>
    ...
    template_variables:
      app_domain: example.com
      my-app: < a href="http://my-app.example.org" >this link</a>
    </pre>

* To use a template variable, add the key (in <%=vars.MY-KEY%> form) to a source file.

    Example source file excerpt:

    <pre>
    I deployed my app to <%=vars.app_domain%>. You can see it by clicking <%=vars.my-app%>.
    </pre>


### Partials

Bookbinder supports **partials**, reusable blocks of source material.

Create a partial by adding a file containing source material to a repository.
The name of the file must start with an underscore.

To use the partial, use the name of the file without the starting underscore in the following code, and add this code to the source file where you want the partial to appear: <%= partial 'FILENAME' %>

### Including Assets

Bookbinder also includes helper code to correctly find image, stylesheet, and javascript assets. When using `<% image_tag ...`, `<% stylesheet_link_tag ...`, or `<% javascript_include_tag ...` to include assets, Bookbinder will search the entire directory structure starting at the top-level until it finds an asset with the provided name. For example, when resolving `<% image_tag 'great_dane.png' %>` called from the page `dogs/big_dogs/index.html.md.erb`, Middleman will first look in `images/great_dane.png.` If that file does not exist, it will try `dogs/images/great_dane.png`, then `dogs/big_dogs/images/great_dane.png`.

## Commands

Bookbinder's entry point is the `bookbinder` executable. It should be invoked from the book directory. The following commands are available:

### `bind` command

Bookbinder's most important command is `bind`. It takes one argument on the command line: `local` or `remote`.

        bin/bookbinder bind local

will find documentation repositories in directories that are siblings to your current directory.

        bin/bookbinder bind remote

will find doc repositories by downloading the latest version from git. Note that if any of the repositories configured as 'sections' are private, you should [create an SSH key](https://help.github.com/articles/generating-ssh-keys/) for Bookbinder from an account that has access to the section repositories.

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

### `watch` command

Bookbinder's command for live previews in development is `watch`. Its functionality is similar to `bind local` in that it only includes repositories stored on disk. It then watches the sections (not the book or layout repositories) for changes and runs a preview server that updates upon file save.

        bin/bookbinder watch

**Note:** CPU usage directly relates to the number of sections your book is watching. If you find that watch is running slowly, either use `bind` or delete unused local repositories.

### `imprint` command

Bookbinder's command for generating PDFs from books is `imprint`. It is currently only supported for DITA, and requires DITA-OT to be [installed locally](#install-ditaot). Generated PDFs will be deposited in `artifacts/pdf`.

It takes one argument on the command line: `local` or `remote`.

        bin/bookbinder imprint local

will find documentation repositories in directories that are siblings to your current directory.

        bin/bookbinder imprint remote

will find doc repositories by downloading the latest version from git.

Optionally and simliar to `bind`, it also takes `--verbose` and `--dita-flags`. There is a known bug with the `--dita-flags` flag that requires escaped quotes surrounding any passed arguments, like so: `--dita-flags=\"my=argument other=argument\"`.

Imprint looks in the config.yml for content specified as `pdf_sections`, as so:

```
pdf_sections:
- repository:
    name: org/content
  ditamap_location: content.ditamap
  ditaval_location: content.ditaval
  output_filename: awesome-pdf
- repository:
    name: org/more-content
  ditamap_location: more-content.ditamap
  ditaval_location: more-content.ditaval
```

Running `imprint` with the config specified above will result in the creation of two pdfs, one called 'awesome-pdf.pdf', as specified under `output_filename`, and the other  defaulting to the name of the ditamap, 'more-content.pdf'.


### `punch` command

For snapshotting books at specific point in time, Bookbinder provides the `punch` command. This command git tags your book, all sections specified in the `config.yml`, and the layout repository (if provided) at the current head of master.

It takes one argument on the command line: the name of the tag you'd like to add.

        bin/bookbinder punch <tag-name>

Note that in order to tag any remote repositories, you will require push access. If you have not already, you should [create an SSH key](https://help.github.com/articles/generating-ssh-keys/) and `ssh-add` the key for Bookbinder from an account that has push access to the repositories.

### `update_local_doc_repos` command

As a convenience, Bookbinder provides a command to update all your local doc repositories, performing a git pull on each one:

        bin/bookbinder update_local_doc_repos

## Running the App Locally

    cd final_app
    bundle
    rackup

This will start a [rack](http://rack.github.io) server to serve your
documentation website locally at
[http://localhost:9292/](http://localhost:9292/). While making edits in
documentation repositories, we recommend leaving this running in a dedicated shell
window. It can be terminated by hitting `ctrl-c`.

## Generating a Sitemap for Google Search Indexing

The sitemap file `/sitemap.xml` is automatically regenerated when binding. When setting up a new docs website, make sure to add this sitemap's url in Google Webmaster Tools (for better reindexing?).

## Contributing to Bookbinder

### Running Tests

To run bookbinder's rspec suite, install binstubs, then run the included rake task:

Once: `bundle install --binstubs`

Then at any time: `bin/rake`
