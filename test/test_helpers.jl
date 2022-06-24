using OnlineLogBinning

function _PairAccumulator_equality(pa1, pa2)
    (pa1.fullpair == pa2.fullpair &&
     all(pa1.values .== pa2.values) )
end

function _LevelAccumulator_equality( la1, la2 )
    ( la1.level == la2.level &&
      la1.num_bins == la2.num_bins &&
      la1.Taccum == la2.Taccum &&
      la1.Saccum == la2.Saccum &&
      _PairAccumulator_equality(la1.Paccum, la2.Paccum) )
end

function _BinningAccumulator_equality( ba1, ba2 )
    all( _LevelAccumulator_equality.(ba1.LvlAccums, ba2.LvlAccums) )
end

function _test_level_statistics(bacc; level, known_mean, known_var, known_var_of_mean, known_std, known_std_err )
    @test mean(bacc; level = level) ≈ known_mean
    @test var(bacc; level = level) ≈ known_var
    @test var_of_mean(bacc; level = level) ≈ known_var_of_mean
    @test std(bacc; level = level) ≈ known_std
    @test std_error(bacc; level = level) ≈ known_std_err
end