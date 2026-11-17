import QtQuick
import qs.theme

// Two faces of a cube turning about the horizontal axis, drawn with plain
// Qt Quick: each face gets a projective matrix that maps it onto the screen
// as seen from a camera in front of the cube.
//
// progress 0 shows `from` face-on, 1 shows `to`; zoom backs the cube away
// from the camera. direction +1 brings `to` up from below (the cube turns away
// from the viewer at the top), -1 brings it down from above.
Item {
    id: root

    property real progress: 0
    property real zoom: 0          // 0 face fills the screen, 1 cube backed away
    property int direction: 1
    property alias from: faceA.content
    property alias to: faceB.content

    // Camera distance and how far the cube backs away at zoom 1, in face
    // heights: 0.5 shows the front face at about 80 % of the screen
    property real cameraDistance: 1.9
    property real pullBack: 0.5

    readonly property real _d: cameraDistance * height
    readonly property real _zoff: -pullBack * height * zoom

    // Projective matrix of a face turned by `beta` degrees about the cube axis
    // (the line y = H/2, z = -H/2). A face point (u, v) lies at
    //     X = u
    //     Y = H/2 + (v - H/2) cos b - H/2 sin b
    //     Z = -H/2 + (v - H/2) sin b + H/2 cos b + zoff
    // and projects to (cx + (X - cx) s, cy + (Y - cy) s) with s = d / (d - Z),
    // i.e. homogeneous (X - cx Z/d, Y - cy Z/d, 1 - Z/d). z is flattened so the
    // scene graph never clips it.
    function faceMatrix(beta) {
        const b = beta * Math.PI / 180;
        const H = height, d = _d, cx = width / 2, cy = height / 2;
        const sin = Math.sin(b), cos = Math.cos(b);
        const oy = H / 2 - H / 2 * cos - H / 2 * sin;
        const oz = -H / 2 - H / 2 * sin + H / 2 * cos + _zoff;
        return Qt.matrix4x4(
            1, -cx * sin / d, 0, -cx * oz / d,
            0, cos - cy * sin / d, 0, oy - cy * oz / d,
            0, 0, 0, 0,
            0, -sin / d, 0, 1 - oz / d);
    }

    // A face shows only while its outward normal points at the camera
    function facesCamera(beta) {
        const b = beta * Math.PI / 180;
        const H = height, sin = Math.sin(b), cos = Math.cos(b);
        const yc = H / 2 - H / 2 * sin;
        const zc = -H / 2 + H / 2 * cos + _zoff;
        return -sin * (height / 2 - yc) + cos * (_d - zc) > 0;
    }

    component Face: Item {
        id: face
        property real beta: 0
        default property alias content: holder.data

        x: 0; y: 0
        width: root.width
        height: root.height
        visible: root.facesCamera(beta)
        transform: Matrix4x4 { matrix: root.faceMatrix(face.beta) }

        Item {
            id: holder
            anchors.fill: parent
            clip: true
        }
        // Light falls from the front: a face turned away darkens
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.62 * Math.abs(Math.sin(face.beta * Math.PI / 180))
        }
        // Glyph light along the edges while the cube stands back
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: 3
            border.color: Theme.cyan
            opacity: 0.85 * root.zoom
        }
    }

    Face { id: faceA; beta: root.direction * 90 * root.progress }
    Face { id: faceB; beta: root.direction * 90 * (root.progress - 1) }
}
