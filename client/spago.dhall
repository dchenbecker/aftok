{ name = "halogen-project"
, dependencies = 
    [ "console"
    , "effect"
    , "halogen"
    , "psci-support"
    , "affjax"
    , "halogen-css"
    , "argonaut-codecs" 
    ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
