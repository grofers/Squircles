# Squircles

## Integration

To integrate Squircles into your app, follow these steps:

1. Import `ZSquirclesView` folder into your project.
2. For any view you wish to support a squircle shape, inherit it from `ZSquircleView`. ZSquircleView is a subclass of UIView, providing all the functionalities of a standard UIView.
3. Instead of using the traditional view.addSubview(...), utilize the following approach:

```Swift
view.squircleContentView.addSubview(containerView)
```
4. When setting the corner radius, instead of `view.layer.cornerRadius = x`, use the following:
```Swift
view.squircleCornerRadius = 8
```

Voila, you implemented your first squicle view. 

> In the case you are wondering how can one spot the difference between a normal view and squircle view, the following is an example.
> 
> ![](https://github.com/ZKanishkaGrofers/ZSquircleView/assets/135613655/36aa82e7-82f6-44cd-ba0c-acdc3fed5343)


## Styling
### Border Configuration

To set the border of the squircle view, employ the following code:

```Swift
view.borderConfig = ZSquircleView.BorderConfig(width: 1.0, color: .green)
```

### Shadow Configurations 

To add shadow of the squircle view, employ the following code:

```Swift
view.shadowConfig = ZSquircleView.ShadowConfig(color: .black, offset: CGSize(width: 0, height: 1), radius: 2, opacity: 0.08)
``` 

### Customizing Specific Corners

If you wish to apply these properties to a specific corners, use the following:

```Swift
view.squircleCorners = .topCorners // in case of top corners 
```

Available options for corners:
* Top corners `.topCorners`
* Top left `.topLeft`
* Top right `.topRight`
* Bottom corners `.bottomCorners`
* Bottom left `.bottomLeft`
* Bottom right `.bottomRight`
* No corners `noCorners`
* All corners `allCorners`

If you have any feedback or suggestions, please create an issue or raise a pull request.
