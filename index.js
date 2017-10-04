const AWS  = require('aws-sdk')
const path = require('path');
const tar  = require('tar-fs')
const fs   = require('fs-extra')

const { spawn } = require('child_process');
const s3 = new AWS.S3()

exports.handler = (event, context, callback) => {
  var prefix = '/tmp/opt';

  fs.remove(prefix, (err) => {
    if (err) {
      return console.error(err)
    }

    console.log('removed `'+prefix+'`')
  })

  const s3obj = s3.getObject({
    Bucket: 'dweomer-' + process.env.AWS_REGION,
    Key: 'lambda/pkg/git-2.14-openssh-7.5.tar'
  })

  const reader = s3obj.createReadStream()
  const writer = tar.extract(prefix)

  reader.pipe(writer)
  reader.on('end', function(){
    var GIT_TEMPLATE_DIR = path.join(prefix, 'share/git-core/templates');
    var GIT_EXEC_PATH = path.join(prefix, 'libexec/git-core');
    var LD_LIBRARY_PATH = path.join(prefix, 'lib64');
    var GIT_PATH = path.join(prefix, 'bin');

    process.env.PATH = process.env.PATH + ":" + GIT_PATH
    process.env.GIT_TEMPLATE_DIR = GIT_TEMPLATE_DIR;
    process.env.GIT_EXEC_PATH = GIT_EXEC_PATH;
    process.env.LD_LIBRARY_PATH = process.env.LD_LIBRARY_PATH
        ? process.env.LD_LIBRARY_PATH + ":" + LD_LIBRARY_PATH
        : LD_LIBRARY_PATH;

    const git = spawn('exec', ['git', '--version'], {shell: true});

    git.stdout.on('data', (data) => {
      console.log(`stdout: ${data}`);
    });

    git.stderr.on('data', (data) => {
      console.log(`stderr: ${data}`);
    });

    git.on('close', (code) => {
      callback(null, {code: code})
    });

  });
};
