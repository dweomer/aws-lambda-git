const aws  = require('aws-sdk')
const fs   = require('fs-extra')
const path = require('path')
const tar  = require('tar-fs')

const { spawn } = require('child_process')

exports.handler = (event, context, callback) => {
  const s3 = new aws.S3()
  const installationS3Object = s3.getObject({
    Bucket: 'dweomer-' + process.env.AWS_REGION,
    Key: 'lambda/pkg/git-2.14-openssh-7.5.tar'
  })
  const installationRoot = '/tmp/opt'
  const installationReader = installationS3Object.createReadStream()
  const installationWriter = tar.extract(installationRoot)

  fs.removeSync(installationRoot)

  installationReader.pipe(installationWriter)
  installationWriter.on('finish', () => {
    const GIT_DIR = '/tmp/src'
    const GIT_BIN_DIR = path.join(installationRoot, 'bin')
    const GIT_EXEC_PATH = path.join(installationRoot, 'libexec/git-core')
    const GIT_LIBRARY_PATH = path.join(installationRoot, 'lib64')
    const GIT_TEMPLATE_DIR = path.join(installationRoot, 'share/git-core/templates')

    process.env.PATH = process.env.PATH + ":" + GIT_BIN_DIR
    process.env.GIT_TEMPLATE_DIR = GIT_TEMPLATE_DIR
    process.env.GIT_EXEC_PATH = GIT_EXEC_PATH
    process.env.LD_LIBRARY_PATH = process.env.LD_LIBRARY_PATH
        ? process.env.LD_LIBRARY_PATH + ":" + GIT_LIBRARY_PATH
        : GIT_LIBRARY_PATH

    const gitClone = spawn('git', ['clone', 'https://github.com/dweomer/aws-lambda-git.git', '--quiet', '--branch', 'master', GIT_DIR])

    gitClone.stdout.on('data', (data) => {
      console.log(`stdout: ${data}`)
    })

    gitClone.stderr.on('data', (data) => {
      console.log(`stderr: ${data}`)
    })

    gitClone.on('close', (code) => {
      const find = spawn('find', [GIT_DIR])

      find.stdout.on('data', (data) => {
        console.log(`stdout: ${data}`)
      })

      find.stderr.on('data', (data) => {
        console.log(`stderr: ${data}`)
      })

      find.on('close', (code) => {
        callback(null, {exit: code})
      })
    })

    // git('/tmp').clone('https://github.com/dweomer/aws-lambda-git.git', GIT_DIR, ['--branch', 'master'], (err,data) => {
    //   if (!err) {
    //     console.log(`completed checkout into ${GIT_DIR}`)
    //     try {
    //       process.chdir(GIT_DIR)
    //       console.log(`changed working directory to ${process.cwd()}`)
    //     } catch (err) {
    //       console.log(`stderr: ${err}`)
    //     }
    //   }
    // })
  })
}
