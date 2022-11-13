use bevy::{
    diagnostic::{FrameTimeDiagnosticsPlugin, LogDiagnosticsPlugin},
    prelude::*,
    render::camera::ScalingMode,
};
fn main() {
    App::new()
        .insert_resource(ClearColor(Color::BLACK))
        .add_plugins(DefaultPlugins)
        .add_plugin(LogDiagnosticsPlugin::default())
        .add_plugin(FrameTimeDiagnosticsPlugin::default())
        .add_system(bevy::window::close_on_esc)
        .add_startup_system(setup)
        .add_system(rotate)
        .run();
}

fn setup(mut commands: Commands, asset_server: Res<AssetServer>) {
    // Camera
    commands.spawn(Camera2dBundle {
        projection: OrthographicProjection {
            scaling_mode: ScalingMode::Auto {
                min_width: 1.0,
                min_height: 1.0,
            },
            ..Default::default()
        },
        ..Default::default()
    });

    // Sprite
    let img = asset_server.load("bevy.png");
    commands.spawn(SpriteBundle {
        texture: img,
        sprite: Sprite {
            custom_size: Some(Vec2::new(0.6, 0.6)),
            ..Default::default()
        },
        ..Default::default()
    });
}

fn rotate(mut query: Query<&mut Transform, With<Sprite>>, time: Res<Time>) {
    for mut tr in &mut query {
        tr.rotate_local_z(-time.delta_seconds());
    }
}
