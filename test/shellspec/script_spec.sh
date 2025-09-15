Describe 'biome.sh'
  Include lib/biome.sh
  cd test || exit

  biome() {
    npx @biomejs/biome "$@"
  }

  install_biome() {
    npm install

    echo "Biome $(biome --version)"
  }

  # Undo changes made by `biome check --write` command
  setup() {
    stty cols 100 rows 24 2>/dev/null || true
    cp -r testdata testdata_origin
  }
  cleanup() {
    rm -rf testdata
    mv testdata_origin testdata
  }
  BeforeEach 'setup'
  AfterEach 'cleanup'

  Describe 'biome_check function'
    install_biome

    It 'output nothing when there is no error'
      When call biome_check testdata/ok/
      The output should eq ''
    End

    It 'output error when there is an error'
      When call biome_check testdata/error/
      The output should eq "$(cat testdata/error/expected_output/check.txt)"
    End
  End

  Describe 'biome_ci function'
    install_biome

    It 'output nothing when there is no error'
      When call biome_ci testdata/ok/
      The output should eq ''
    End

    It 'output error when there is an error'
      When call biome_ci testdata/error/
      The output should eq "$(cat testdata/error/expected_output/ci.txt)"
    End
  End
End
