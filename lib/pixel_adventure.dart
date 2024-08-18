import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/components/level.dart';
import 'package:pixel_adventure/components/player.dart';

class PixelAdventure extends FlameGame
    with HasKeyboardHandlerComponents, DragCallbacks, HasCollisionDetection {
  late CameraComponent cam;
  late JoystickComponent joystick;
  Player player = Player();

  @override
  Color backgroundColor() => const Color(0xFF211F30);

  @override
  FutureOr<void> onLoad() async {
    //load all image into cache
    await images.loadAllImages();
    final world = Level(levelName: 'Level-01', player: player);
    cam = CameraComponent.withFixedResolution(
        width: 640, height: 360, world: world);
    cam.viewfinder.anchor = Anchor.topLeft;
    cam.viewport.add(addJoystick());
    addAll([cam, world]);

    return super.onLoad();
  }

  @override
  void update(double dt) {
    _updateJoystick();
    super.update(dt);
  }

  JoystickComponent addJoystick() {
    joystick = JoystickComponent(
      knob: SpriteComponent(
        sprite: Sprite(
          images.fromCache('HUD/Knob.png'),
        ),
      ),
      priority: 1,
      background: SpriteComponent(
        sprite: Sprite(
          images.fromCache('HUD/Joystick.png'),
        ),
      ),
      margin: const EdgeInsets.only(right: 32, bottom: 5),
    );
    return joystick;
  }

  void _updateJoystick() {
    switch (joystick.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        player.horizontalMovement = -1;
        break;
      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        player.horizontalMovement = 1;
        break;
      default:
        player.horizontalMovement = 0;
        break;
    }
  }
}
