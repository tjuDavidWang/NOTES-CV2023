import cv2
import os

# 图像保存目录（需要替换）
img_dir_name = "path_to_save_images" 

# 检查文件夹是否存在，如果不存在，则创建
if not os.path.exists(img_dir_name):
    os.makedirs(img_dir_name)

# 棋盘格参数
board_size = (9, 6)
pattern_size = (9, 6)

# 初始化变量
frame_index = 1
imgs_collected = 0

# 打开摄像头
cap = cv2.VideoCapture(0)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 768)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1024)

# 检查摄像头是否成功打开
if not cap.isOpened():
    print("打开相机失败")
    exit(-1)

# 捕捉和处理帧
while True:
    ret, frame = cap.read()
    if not ret:
        continue

    cv2.imshow("Camera", frame)
    key = cv2.waitKey(1)

    if key == 27:  # 按下 Esc 键退出
        break

    if key == ord('q') or key == ord('Q'):
        # 检测棋盘格角点
        ret, corners = cv2.findChessboardCorners(frame, pattern_size)

        if not ret:
            print("无法找到棋盘格角点！")
            continue
        else:
            # 精细化角点位置
            corners2 = cv2.cornerSubPix(cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY), corners, (11, 11), (-1, -1), 
                                        (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 100, 0.001))
            
            # 可视化角点
            iImageTemp = frame.copy()
            cv2.drawChessboardCorners(iImageTemp, pattern_size, corners2, ret)
            cv2.imshow("Camera", iImageTemp)
            cv2.waitKey(1000)  # 显示 1 秒

            # 保存图像
            img_name = os.path.join(img_dir_name, f"{frame_index}.jpg")
            cv2.imwrite(img_name, frame)  # 保存带有标记的图像
            frame_index += 1
            imgs_collected += 1
            print(f"{imgs_collected} 张图片已采集！")

print("完成标定板图像采集")
cap.release()
cv2.destroyAllWindows()
