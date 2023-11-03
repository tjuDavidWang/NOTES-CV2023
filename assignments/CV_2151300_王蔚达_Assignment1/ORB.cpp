/*************************************************************************************************************************
    Program: ORB Feature Point Matching
    Description: This program matches feature points between two images using the ORB descriptor and draws the matches.

    Setting up the development environment:

    1. Install OpenCV:
    - For Windows: Follow the guide at https://docs.opencv.org/master/d3/d52/tutorial_windows_install.html
    - For Linux:   Follow the guide at https://docs.opencv.org/master/d7/d9f/tutorial_linux_install.html
    - For MacOS:   Use homebrew or follow the guide at https://docs.opencv.org/master/d0/db2/tutorial_macos_install.html

    2. Compiler Requirements:
    - A C++ compiler supporting C++11 or above.

    3. To Compile and Run:
    $ g++ -std=c++11 ORB.cpp -o output `pkg-config --cflags --libs opencv4`

    4. Make sure the images "sse1.bmp" and "sse2.bmp" are in the current directory or provide the correct path.
*************************************************************************************************************************/
#include <iostream>
#include <opencv2/opencv.hpp>
#include <opencv2/features2d.hpp>
#include <opencv2/highgui/highgui.hpp>

using namespace std;
using namespace cv;

int main() {
    // Specify the path of the images directly
    string imgPath1 = "sse1.bmp";
    string imgPath2 = "sse2.bmp";

    // Load the images in color
    Mat img1 = imread(imgPath1, IMREAD_COLOR);
    Mat img2 = imread(imgPath2, IMREAD_COLOR);
    if (img1.empty() || img2.empty()) {
        cout << "Cannot open or find the images!" << endl;
        return -1;
    }

    // Convert to grayscale for feature detection
    Mat gray1, gray2;
    cvtColor(img1, gray1, COLOR_BGR2GRAY);
    cvtColor(img2, gray2, COLOR_BGR2GRAY);

    // Detect ORB keypoints and descriptors
    Ptr<Feature2D> orb = ORB::create();
    vector<KeyPoint> keypoints1, keypoints2;
    Mat descriptors1, descriptors2;
    orb->detectAndCompute(gray1, noArray(), keypoints1, descriptors1);
    orb->detectAndCompute(gray2, noArray(), keypoints2, descriptors2);

    // Use brute-force matcher
    BFMatcher matcher(NORM_HAMMING);
    vector<vector<DMatch>> knn_matches;
    matcher.knnMatch(descriptors1, descriptors2, knn_matches, 2);

    // Ratio test & Cross matching
    vector<DMatch> good_matches;
    for (size_t i = 0; i < knn_matches.size(); i++) {
        if (knn_matches[i][0].distance < 0.75 * knn_matches[i][1].distance) {
            good_matches.push_back(knn_matches[i][0]);
        }
    }

    // Draw the matches on the color images
    Mat img_matches;
    drawMatches(img1, keypoints1, img2, keypoints2, good_matches, img_matches);

    // Display the match result
    imshow("ORB Feature Point Matching", img_matches);
    waitKey(0);

    return 0;
}
