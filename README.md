# Abysall Fork
A restyled fork of Abysall Hub by FireBacon (bocaj111004).

Try it if you want:
```
loadstring(game:HttpGet("https://raw.githubusercontent.com/lukasos-gd/Abysall-Fork/refs/heads/main/Loader.luau"))()
```

## Pin a version
Set a tag before running the loader so pushes to main can't break your copy:
```
getgenv().AbysallRef = "refs/tags/v1.0.0"
loadstring(game:HttpGet("https://raw.githubusercontent.com/lukasos-gd/Abysall-Fork/refs/tags/v1.0.0/Loader.luau"))()
```

## Releasing
```
git tag -a v1.0.1 -m "v1.0.1"
git push origin v1.0.1
```
Update `Changelog.json` and `Abysall.Version` in `Loader.luau` first.

Original: https://github.com/bocaj111004/Abysall
