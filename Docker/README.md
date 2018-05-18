A simple Dockerfile for executing bookbinder on your system.

## Procedure

1. Download the `Dockerfile` to a local directory and change to that directory.
2. Build and tag a new image:
    ``` bash
    $ docker build -t docs/bb .
    ```
3. Run the image using a command similar to:
    ``` bash
    $ docker run -it -p 9292:9292 -p 1234:1234 -v /my/github/directory:/github docs/bb
    ```

    Substitute your local Github directory with for `/my/github/directory` in the above command.

4. Within the docker image, go to a directory containing your book configuration.  Execute:
    ``` bash
    $ bundle install
    ```

5. Execute bookbinder commands to build or review your work, such as:

    * `bundle exec bookbinder bind local`
    * `bundle exec bookbinder watch`
    * `rackup` from a `/final_app` directory

## Limitations

- The docker image is only configured for building MarkDown content.  DITA builds aren't yet supported.
- The docker image only works for local builds.  You'll need to configure Github authentication within your local image to perform remote builds.
