import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/components/custom_hitbox.dart';
import 'package:pixel_adventure/components/fruit.dart';
import 'package:pixel_adventure/components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

import 'collision_block.dart';

enum PlayerState { idle, running, hit, falling, jumping, doubleJump, wallJump }

class Player extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, KeyboardHandler, CollisionCallbacks {
  final String character;
  Player({
    position,
    this.character = 'Ninja Frog',
  }) : super(position: position);

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation hitAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation fallingAnimation;
  late final SpriteAnimation doubleJumpAnimation;
  late final SpriteAnimation wallJumpAnimation;
  final double stepTime = 0.05;
  final double textureSize = 32;

  final double _gravity = 9.8;
  final double _jumpForce = 290;
  final double _terminalVelocity = 300;
  double horizontalMovement = 0;
  double moveSpeed = 100;
  Vector2 velocity = Vector2.zero();
  List<CollisionBlock> collisionBlocks = [];
  bool isOnGround = false;
  bool hasJumped = false;
  CustomHitbox hitbox = CustomHitbox(
    offsetX: 10,
    offsetY: 4,
    width: 14,
    height: 28,
  );
  @override
  FutureOr<void> onLoad() {
    _loadAllAnimation();
    add(
      RectangleHitbox(
        position: Vector2(hitbox.offsetX, hitbox.offsetY),
        size: Vector2(hitbox.width, hitbox.height),
      ),
    );
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _updatePlayerState();
    _updatePlayerMovement(dt);
    _checkHorizontalCollisions();
    _applyGravity(dt);
    _checkVerticalCollisions();
    super.update(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0;
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight);
    horizontalMovement += isLeftKeyPressed ? -1 : 0;
    horizontalMovement += isRightKeyPressed ? 1 : 0;

    hasJumped = keysPressed.contains(LogicalKeyboardKey.space) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp);

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Fruit) other.collidedWithPlayer();
    super.onCollisionStart(intersectionPoints, other);
  }

  void _loadAllAnimation() {
    idleAnimation = _createSpriteAnimation(state: 'Idle', amount: 11);
    runningAnimation = _createSpriteAnimation(state: 'Run', amount: 12);
    hitAnimation = _createSpriteAnimation(state: 'Hit', amount: 7);
    jumpingAnimation = _createSpriteAnimation(state: 'Jump', amount: 1);
    fallingAnimation = _createSpriteAnimation(state: 'Fall', amount: 1);
    doubleJumpAnimation =
        _createSpriteAnimation(state: 'Double Jump', amount: 6);

    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.hit: hitAnimation,
      PlayerState.jumping: jumpingAnimation,
      PlayerState.falling: fallingAnimation,
    };

    current = PlayerState.idle;
  }

  void _updatePlayerMovement(double dt) {
    if (hasJumped && isOnGround) _playerJump(dt);

    //if (velocity.y > _gravity) isOnGround = false;
    velocity.x = horizontalMovement * moveSpeed;
    position.x += velocity.x * dt;
  }

  void _playerJump(double dt) {
    velocity.y = -_jumpForce;
    position.y += velocity.y * dt;
    isOnGround = false;
    hasJumped = false;
  }

  SpriteAnimation _createSpriteAnimation(
      {required String state, required int amount}) {
    return SpriteAnimation.fromFrameData(
        gameRef.images
            .fromCache('Main Characters/$character/$state (32x32).png'),
        SpriteAnimationData.sequenced(
          amount: amount,
          stepTime: stepTime,
          textureSize: Vector2.all(textureSize),
        ));
  }

  void _updatePlayerState() {
    PlayerState playerState = PlayerState.idle;
    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }
    //check if moving set running
    if (velocity.x > 0 || velocity.x < 0) playerState = PlayerState.running;

    //check if falling
    if (velocity.y > _gravity) playerState = PlayerState.falling;
    //check if jumping
    if (velocity.y < 0) playerState = PlayerState.jumping;
    current = playerState;
  }

  void _checkHorizontalCollisions() {
    for (final block in collisionBlocks) {
      if (!block.isPlatform) {
        if (checkCollision(player: this, block: block)) {
          if (velocity.x > 0) {
            velocity.x = 0;
            position.x = block.x - hitbox.offsetX - hitbox.width;
            break;
          }
          if (velocity.x < 0) {
            velocity.x = 0;
            position.x = block.x + block.width + hitbox.width + hitbox.offsetX;
            break;
          }
        }
      }
    }
  }

  void _applyGravity(double dt) {
    velocity.y += _gravity;
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
    position.y += velocity.y * dt;
  }

  void _checkVerticalCollisions() {
    for (final block in collisionBlocks) {
      if (block.isPlatform) {
        if (checkCollision(player: this, block: block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
        }
      } else {
        if (checkCollision(player: this, block: block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
          if (velocity.y < 0) {
            velocity.y = 0;
            position.y = block.y + block.height - hitbox.offsetY;
          }
        }
      }
    }
  }
}
