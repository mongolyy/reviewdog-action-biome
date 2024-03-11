Describe 'biome.sh'
  Include lib/biome.sh
  cd test || exit

  # Undo changes made by `biome check --apply` command
  setup() {
    cp -r testdata testdata_origin
  }
  cleanup() {
    rm -rf testdata
    mv testdata_origin testdata
  }
  BeforeEach 'setup'
  AfterEach 'cleanup'

  Describe 'install_biome function'
    It 'install biome'
      When call install_biome
      The output should include 'Biome Version: '
    End
  End

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
