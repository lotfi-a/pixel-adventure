import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/player.dart';

bool checkCollision({required Player player, required CollisionBlock block}) {
  final hitbox = player.hitbox;

  final playerX = player.position.x + hitbox.offsetX;
  final playerY = player.position.y + hitbox.offsetY;
  final playerW = hitbox.width;
  final playerH = hitbox.height;

  final blockX = block.x;
  final blockY = block.y;
  final blockW = block.width;
  final blockH = block.height;

  final fixeX =
      player.scale.x < 0 ? playerX - (hitbox.offsetX * 2) - playerW : playerX;
  final fixeY = block.isPlatform ? playerY + playerH : playerY;

  return (fixeY < blockY + blockH &&
      fixeY + playerH > blockY &&
      fixeX < blockX + blockW &&
      fixeX + playerW > blockX);
}
