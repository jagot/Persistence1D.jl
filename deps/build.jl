using BinDeps

@BinDeps.setup

libpersistence1d = library_dependency("libpersistence1d")

prefix = joinpath(BinDeps.depsdir(libpersistence1d), "usr")
src_dir = joinpath(BinDeps.depsdir(libpersistence1d), "src", "Persistence1D")
build_dir = joinpath(BinDeps.depsdir(libpersistence1d), "builds", "Persistence1D")

provides(SimpleBuild,
         (@build_steps begin
          CreateDirectory(build_dir)
          @build_steps begin
          ChangeDirectory(build_dir)
          @build_steps begin
          `cmake -DCMAKE_INSTALL_PREFIX="$prefix" $src_dir`
          `make`
          `make install`
          end
          end
          end),
         libpersistence1d)
@BinDeps.install Dict([(:libpersistence1d, :_jl_libpersistence1d)])
