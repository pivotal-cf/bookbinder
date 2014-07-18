#Updating wkhtmltopdf

Bookbinder uses a [fork of wkhtmltopdf](https://github.com/pivotal-cf-experimental/wkhtmltopdf).

It is compiled as a debug build and stripped to reduce size. The debug build is able to generate PDFs with headers and many HTML inputs, but for some reason the non debug build cannot. wkhtmltopdf was developed for use on a **Linux environment**.

##Compiling

###On an Ubuntu Trusty VM

Clone https://github.com/pivotal-cf-experimental/wkhtmltopdf

[Set up build environment](https://github.com/pivotal-cf-experimental/wkhtmltopdf/blob/master/INSTALL.md) by running:

```sh
sudo scripts/build.py setup-schroot-trusty
```

##Building

###64-bit debug binary:

```sh
./scripts/build.py trusty-amd64 -debug
```

Install the deb, making sure to change the SHA in the deb filename to the one output by the previous step:

```sh
sudo dpkg -i static-build/wkhtmltox-0.12.2-4973d55_linux-trusty-amd64.deb
```

###32-bit debug binary:

Make sure to change the SHA in the deb filename to the one output by the previous step:

```sh
./scripts/build.py trusty-i386 -debug
mkdir -p /tmp/wkhtmltopdf
dpkg -x static-build/wkhtmltox-0.12.2-4973d55_linux-trusty-amd64.deb /tmp/wkhtmltopdf
cp /tmp/wkhtmltopdf/usr/local/bin/wkhtmltopdf /tmp/wkhtmltopdf
```

##Updating the Gem
###64-bit:

```sh
git clone https://github.com/pivotal-cf-experimental/wkhtmltopdf_binary_gem.git
cp /usr/local/bin/wkhtmltopdf /tmp
strip /tmp/wkhtmltopdf
```

Copy /tmp/wkhtmltopdf to `bin/wkhtmltopdf_linux_x64` in the gem repo.

###32-bit:

```sh
git clone https://github.com/pivotal-cf-experimental/wkhtmltopdf_binary_gem.git
cp /usr/local/bin/wkhtmltopdf /tmp
strip /tmp/wkhtmltopdf
```

Copy the binary to `bin/wkhtmltopdf_linux_386`

##Pushing

Commit, bump the version in the gemspec in the Rakefile.

```sh
gem push
```

The RubyGems credentials are found in LastPass.
`
