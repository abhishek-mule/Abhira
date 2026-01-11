import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:abhira/Dashboard/Articles%20-%20SafeCarousel/ArticleDesc.dart';
import 'package:abhira/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class SafeCarousel extends StatelessWidget {
  const SafeCarousel({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      debugPrint('Could not launch $url');
    }
  }

  void _handleTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        _launchUrl(
          "https://www.seniority.in/blog/10-women-who-changed-the-face-of-india-with-their-achievements/",
        );
        break;
      case 1:
        _launchUrl(
          "https://plan-international.org/ending-violence/16-ways-end-violence-girls",
        );
        break;
      case 2:
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => ArticleDesc(index: index),
          ),
        );
        break;
      default:
        _launchUrl(
          "https://www.healthline.com/health/womens-health/self-defense-tips-escape",
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Swiper(
        itemCount: imageSliders.length,
        autoplay: true,
        viewportFraction: 0.8,
        scale: 0.9,
        itemBuilder: (context, index) {
          return Hero(
            tag: articleTitle[index],
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _handleTap(context, index),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageSliders[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Center(child: Icon(Icons.broken_image)),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black54,
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      right: 12,
                      child: Text(
                        articleTitle[index],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

