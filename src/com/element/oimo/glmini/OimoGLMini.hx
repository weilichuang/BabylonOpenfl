/* Copyright (c) 2012-2013 EL-EMENT saharan
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation  * files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy,  * modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to
 * whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or
 * substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 * PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
 * ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
package com.element.oimo.glmini;

import com.adobe.utils.AGALMiniAssembler;
import com.element.oimo.math.Mat44;
import com.element.oimo.math.Vec3;
import flash.display3D.Context3D;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DTriangleFace;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.VertexBuffer3D;
import flash.errors.Error;
import flash.utils.ByteArray;
import flash.Vector;

/**
 * A simple 3d engine.
 * @author saharan
 */
class OimoGLMini
{
	private static inline var VERTEX_POISITION_INDEX:Int = 0;
	private static inline var VERTEX_NORMAL_INDEX:Int = 1;
	private static inline var FRAGMENT_COLOR_INDEX:Int = 0;
	private static inline var FRAGMENT_AMB_DIF_EMI_INDEX:Int = 1;
	private static inline var FRAGMENT_SPC_SHN_INDEX:Int = 2;
	private static inline var FRAGMENT_AMB_LIGHT_COLOR_INDEX:Int = 3;
	private static inline var FRAGMENT_DIR_LIGHT_COLOR_INDEX:Int = 4;
	private static inline var FRAGMENT_DIR_LIGHT_DIRECTION_INDEX:Int = 5;
	private static inline var FRAGMENT_CAMERA_POSITION_INDEX:Int = 6;
	private var c3d:Context3D;
	private var w:Int;
	private var h:Int;
	private var aspect:Float;
	private var worldM:Mat44;
	private var viewM:Mat44;
	private var projM:Mat44;
	private var viewProjM:Mat44;
	private var up:Vector<Float>;
	private var stackM:Vector<Mat44>;
	private var numStack:Int;
	private var vertexB:Vector<VertexBuffer3D>;
	private var numVerticesB:Vector<UInt>;
	private var indexB:Vector<IndexBuffer3D>;
	private var numIndicesB:Vector<UInt>;
	
	public function new(c3d:Context3D, w:Int, h:Int, antiAlias:Int = 0)
	{
		this.c3d = c3d;
		c3d.configureBackBuffer(w, h, antiAlias, true);
		c3d.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
		c3d.setCulling(Context3DTriangleFace.FRONT); // ClockWise
		this.w = w;
		this.h = h;
		aspect = w / h;
		worldM = new Mat44();
		viewM = new Mat44();
		projM = new Mat44();
		viewProjM = new Mat44();
		up = new Vector<Float>(4, true);
		stackM = new Vector<Mat44>(256, true);
		vertexB = new Vector<VertexBuffer3D>(256, true);
		numVerticesB = new Vector<UInt>(256, true);
		indexB = new Vector<IndexBuffer3D>(256, true);
		numIndicesB = new Vector<UInt>(256, true);
		numStack = 0;
		var program:Program3D = c3d.createProgram();
		var vs:AGALMiniAssembler = new AGALMiniAssembler();
		vs.assemble(Context3DProgramType.VERTEX, createBasicVertexShaderCode(VERTEX_POISITION_INDEX, VERTEX_NORMAL_INDEX));
		var fs:AGALMiniAssembler = new AGALMiniAssembler();
		fs.assemble(Context3DProgramType.FRAGMENT, createBasicFragmentShaderCode(VERTEX_POISITION_INDEX, VERTEX_NORMAL_INDEX, FRAGMENT_COLOR_INDEX, FRAGMENT_AMB_DIF_EMI_INDEX, FRAGMENT_SPC_SHN_INDEX, FRAGMENT_AMB_LIGHT_COLOR_INDEX, FRAGMENT_DIR_LIGHT_COLOR_INDEX, FRAGMENT_DIR_LIGHT_DIRECTION_INDEX, FRAGMENT_CAMERA_POSITION_INDEX));
		program.upload(vs.agalcode, fs.agalcode);
		c3d.setProgram(program);
		material(1, 1, 0, 0, 0);
		color(1, 1, 1);
		ambientLightColor(0.2, 0.2, 0.2);
		directionalLightColor(0.8, 0.8, 0.8);
		directionalLightDirection(0, 0, -1);
		camera(0, 0, 100, 0, 0, 0, 0, 1, 0);
		perspective(Math.PI / 3);
	}
	
	public function material(ambient:Float, diffuse:Float, emission:Float, specular:Float, shininess:Float):Void
	{
		setProgramConstantsNumber(Context3DProgramType.FRAGMENT, FRAGMENT_AMB_DIF_EMI_INDEX, ambient, diffuse, emission, 1);
		setProgramConstantsNumber(Context3DProgramType.FRAGMENT, FRAGMENT_SPC_SHN_INDEX, specular, shininess, 0, 1);
	}
	
	public function color(r:Float, g:Float, b:Float, a:Float = 1):Void
	{
		setProgramConstantsNumber(Context3DProgramType.FRAGMENT, FRAGMENT_COLOR_INDEX, r, g, b, a);
	}
	
	public function ambientLightColor(r:Float, g:Float, b:Float):Void
	{
		setProgramConstantsNumber(Context3DProgramType.FRAGMENT, FRAGMENT_AMB_LIGHT_COLOR_INDEX, r, g, b, 1);
	}
	
	public function directionalLightColor(r:Float, g:Float, b:Float):Void
	{
		setProgramConstantsNumber(Context3DProgramType.FRAGMENT, FRAGMENT_DIR_LIGHT_COLOR_INDEX, r, g, b, 1);
	}
	
	public function directionalLightDirection(x:Float, y:Float, z:Float):Void
	{
		setProgramConstantsNumber(Context3DProgramType.FRAGMENT, FRAGMENT_DIR_LIGHT_DIRECTION_INDEX, x, y, z, 1);
	}
	
	public function camera(eyeX:Float, eyeY:Float, eyeZ:Float, atX:Float, atY:Float, atZ:Float, upX:Float, upY:Float, upZ:Float):Void
	{
		setProgramConstantsNumber(Context3DProgramType.FRAGMENT, FRAGMENT_CAMERA_POSITION_INDEX, eyeX, eyeY, eyeZ, 1);
		viewM.lookAt(eyeX, eyeY, eyeZ, atX, atY, atZ, upX, upY, upZ);
	}
	
	public inline function perspective(fovY:Float, near:Float = 0.5, far:Float = 10000):Void
	{
		projM.perspective(fovY, aspect, near, far);
	}
	
	public function beginScene(r:Float, g:Float, b:Float):Void
	{
		worldM.init();
		c3d.clear(r, g, b);
	}
	
	public inline function endScene():Void
	{
		c3d.present();
	}
	
	public function registerBox(bufferIndex:Int, width:Float, height:Float, depth:Float):Void
	{
		width *= 0.5;
		height *= 0.5;
		depth *= 0.5;
		registerBuffer(bufferIndex, 24, 36);
		uploadVertexBuffer(bufferIndex, Vector.ofArray([-width, height, -depth, // top face
			-width, height, depth, width, height, depth, width, height, -depth, -width, -height, -depth, // bottom face
			width, -height, -depth, width, -height, depth, -width, -height, depth, -width, height, -depth, // left face
			-width, -height, -depth, -width, -height, depth, -width, height, depth, width, height, -depth, // right face
			width, height, depth, width, -height, depth, width, -height, -depth, -width, height, depth, // front face
			-width, -height, depth, width, -height, depth, width, height, depth, -width, height, -depth, // back face
			width, height, -depth, width, -height, -depth, -width, -height, -depth]), Vector.ofArray([0., 1, 0, // top face
			0, 1, 0, 0, 1, 0, 0, 1, 0, 0, -1, 0, // bottom face
			0, -1, 0, 0, -1, 0, 0, -1, 0, -1, 0, 0, // left face
			-1, 0, 0, -1, 0, 0, -1, 0, 0, 1, 0, 0, // right face
			1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, // front face
			0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, -1, // back face
			0, 0, -1, 0, 0, -1, 0, 0, -1]));
		uploadIndexBuffer(bufferIndex, Vector.convert(Vector.ofArray([0, 1, 2, // top face
			0, 2, 3, 4, 5, 6, // bottom face
			4, 6, 7, 8, 9, 10, // left face
			8, 10, 11, 12, 13, 14, // right face
			12, 14, 15, 16, 17, 18, // front face
			16, 18, 19, 20, 21, 22, // back face
			20, 22, 23])));
	}
	
	public function registerSphere(bufferIndex:Int, radius:Float, divisionH:Int, divisionV:Int):Void
	{
		var count:Int = 0;
		var theta:Float;
		var phi:Float;
		var dTheta:Float = Math.PI * 2 / divisionH;
		var dPhi:Float = Math.PI / divisionV;
		var numVertices:Int = (divisionV + 1) * divisionH - ((divisionH - 1) << 1);
		var numFaces:Int = (divisionV - 1 << 1) * divisionH;
		var vtx:Vector<Float> = new Vector<Float>(numVertices * 3, true);
		var nrm:Vector<Float> = new Vector<Float>(numVertices * 3, true);
		vtx[count] = 0;
		vtx[count + 1] = radius;
		vtx[count + 2] = 0;
		nrm[count] = 0;
		nrm[count + 1] = 1;
		nrm[count + 2] = 0;
		count += 3;
		phi = dPhi;
		for (i in 1...divisionV)
		{
			theta = 0;
			for (j in 0...divisionH)
			{
				var sp:Float = Math.sin(phi);
				var cp:Float = Math.cos(phi);
				var st:Float = Math.sin(theta);
				var ct:Float = Math.cos(theta);
				vtx[count] = radius * sp * ct;
				vtx[count + 1] = radius * cp;
				vtx[count + 2] = radius * sp * st;
				nrm[count] = sp * ct;
				nrm[count + 1] = cp;
				nrm[count + 2] = sp * st;
				count += 3;
				theta += dTheta;
			}
			phi += dPhi;
		}
		vtx[count] = 0;
		vtx[count + 1] = -radius;
		vtx[count + 2] = 0;
		nrm[count] = 0;
		nrm[count + 1] = -1;
		nrm[count + 2] = 0;
		var idx:Vector<UInt> = new Vector<UInt>(numFaces * 3, true);
		count = 0;
		for (i in 0...divisionV)
		{
			for (j in 0...divisionH)
			{
				if (i == 0)
				{
					idx[count] = 0;
					idx[count + 1] = (j + 1) % divisionH + 1;
					idx[count + 2] = j + 1;
					count += 3;
				}
				else if (i == divisionV - 1)
				{
					idx[count] = numVertices - 1;
					idx[count + 1] = (i - 1) * divisionH + j + 1;
					idx[count + 2] = (i - 1) * divisionH + (j + 1) % divisionH + 1;
					count += 3;
				}
				else
				{
					idx[count] = (i - 1) * divisionH + j + 1;
					idx[count + 1] = (i - 1) * divisionH + (j + 1) % divisionH + 1;
					idx[count + 2] = i * divisionH + (j + 1) % divisionH + 1;
					count += 3;
					idx[count] = (i - 1) * divisionH + j + 1;
					idx[count + 1] = i * divisionH + (j + 1) % divisionH + 1;
					idx[count + 2] = i * divisionH + j + 1;
					count += 3;
				}
			}
		}
		registerBuffer(bufferIndex, numVertices, numFaces * 3);
		uploadVertexBuffer(bufferIndex, vtx, nrm);
		uploadIndexBuffer(bufferIndex, idx);
	}
	
	public function registerCylinder(bufferIndex:Int, radius:Float, height:Float, division:Int):Void
	{
		height *= 0.5;
		var count:Int = 0;
		var theta:Float;
		var dTheta:Float = Math.PI * 2 / division;
		var numVertices:Int = (division << 2) + 2;
		var numFaces:Int = division << 2;
		var vtx:Vector<Float> = new Vector<Float>(numVertices * 3, true);
		var nrm:Vector<Float> = new Vector<Float>(numVertices * 3, true);
		vtx[count] = 0;
		vtx[count + 1] = height;
		vtx[count + 2] = 0;
		nrm[count] = 0;
		nrm[count + 1] = 1;
		nrm[count + 2] = 0;
		count += 3;
		theta = 0;
		
		var st:Float;
		var ct:Float;
		var off:Int;
		for (i in 0...division)
		{
			st = Math.sin(theta);
			ct = Math.cos(theta);
			off = (i + 1) * 3;
			vtx[off] = radius * ct;
			vtx[off + 1] = height;
			vtx[off + 2] = radius * st;
			nrm[off] = 0;
			nrm[off + 1] = 1;
			nrm[off + 2] = 0;
			off += division * 3;
			vtx[off] = radius * ct;
			vtx[off + 1] = height;
			vtx[off + 2] = radius * st;
			nrm[off] = ct;
			nrm[off + 1] = 0;
			nrm[off + 2] = st;
			off += division * 3;
			vtx[off] = radius * ct;
			vtx[off + 1] = -height;
			vtx[off + 2] = radius * st;
			nrm[off] = ct;
			nrm[off + 1] = 0;
			nrm[off + 2] = st;
			off += division * 3;
			vtx[off] = radius * ct;
			vtx[off + 1] = -height;
			vtx[off + 2] = radius * st;
			nrm[off] = 0;
			nrm[off + 1] = -1;
			nrm[off + 2] = 0;
			count += 12;
			theta += dTheta;
		}
		vtx[count] = 0;
		vtx[count + 1] = -height;
		vtx[count + 2] = 0;
		nrm[count] = 0;
		nrm[count + 1] = -1;
		nrm[count + 2] = 0;
		count = 0;
		var idx:Vector<UInt> = new Vector<UInt>(numFaces * 3, true);
		for (i in 0...division)
		{
			idx[count] = 0;
			idx[count + 1] = (i + 1) % division + 1;
			idx[count + 2] = i + 1;
			count += 3;
			off = division + 1;
			idx[count] = off + i;
			idx[count + 1] = off + (i + 1) % division;
			idx[count + 2] = off + (i + 1) % division + division;
			count += 3;
			idx[count] = off + i;
			idx[count + 1] = off + (i + 1) % division + division;
			idx[count + 2] = off + i + division;
			count += 3;
			off = division * 3 + 1;
			idx[count] = off + division;
			idx[count + 1] = off + i;
			idx[count + 2] = off + (i + 1) % division;
			count += 3;
		}
		registerBuffer(bufferIndex, numVertices, numFaces * 3);
		uploadVertexBuffer(bufferIndex, vtx, nrm);
		uploadIndexBuffer(bufferIndex, idx);
	}
	
	public function registerBuffer(bufferIndex:Int, numVertices:Int, numIndices:Int):Void
	{
		if (vertexB[bufferIndex] != null)
		{
			vertexB[bufferIndex].dispose();
			indexB[bufferIndex].dispose();
		}
		vertexB[bufferIndex] = c3d.createVertexBuffer(numVertices, 6);
		numVerticesB[bufferIndex] = numVertices;
		indexB[bufferIndex] = c3d.createIndexBuffer(numIndices);
		numIndicesB[bufferIndex] = numIndices;
	}
	
	public function uploadVertexBuffer(bufferIndex:Int, vertices:Vector<Float>, normals:Vector<Float>):Void
	{
		var numVertices:Int = numVerticesB[bufferIndex];
		var arrayCount:Int = numVertices * 3;
		var upload:Vector<Float> = new Vector<Float>(arrayCount << 1, true);
		var num:Int = 0;
		
		var i:Int = 0; 
		while (i < arrayCount)
		{
			upload[num++] = vertices[i];
			upload[num++] = vertices[i + 1];
			upload[num++] = vertices[i + 2];
			upload[num++] = normals[i];
			upload[num++] = normals[i + 1];
			upload[num++] = normals[i + 2];
			
			i += 3;
		}
		vertexB[bufferIndex].uploadFromVector(upload, 0, numVertices);
	}
	
	public function uploadIndexBuffer(bufferIndex:Int, indices:Vector<UInt>):Void
	{
		indexB[bufferIndex].uploadFromVector(indices, 0, numIndicesB[bufferIndex]);
	}
	
	public function drawTriangles(bufferIndex:Int):Void
	{
		c3d.setVertexBufferAt(0, vertexB[bufferIndex], 0, Context3DVertexBufferFormat.FLOAT_3);
		c3d.setVertexBufferAt(1, vertexB[bufferIndex], 3, Context3DVertexBufferFormat.FLOAT_3);
		setProgramConstantsMatrix(Context3DProgramType.VERTEX, 0, worldM);
		viewProjM.mul(projM, viewM);
		setProgramConstantsMatrix(Context3DProgramType.VERTEX, 4, viewProjM);
		c3d.drawTriangles(indexB[bufferIndex]);
	}
	
	public function translate(tx:Float, ty:Float, tz:Float):Void
	{
		worldM.mulTranslate(worldM, tx, ty, tz);
	}
	
	public function scale(sx:Float, sy:Float, sz:Float):Void
	{
		worldM.mulScale(worldM, sx, sy, sz);
	}
	
	public function rotate(rad:Float, ax:Float, ay:Float, az:Float):Void
	{
		worldM.mulRotate(worldM, rad, ax, ay, az);
	}
	
	public function transform(m:Mat44):Void
	{
		worldM.mul(worldM, m);
	}
	
	public function push():Void
	{
		if (numStack < 256)
		{
			if (stackM[numStack] == null)
				stackM[numStack] = new Mat44();
			stackM[numStack++].copy(worldM);
		}
		else
		{
			throw new Error("too many stacks.");
		}
	}
	
	public function pop():Void
	{
		if (numStack > 0)
		{
			worldM.copy(stackM[--numStack]);
		}
		else
		{
			throw new Error("there is no stack.");
		}
	}
	
	public function loadWorldMatrix(m:Mat44):Void
	{
		worldM.copy(m);
	}
	
	public function loadViewMatrix(m:Mat44):Void
	{
		viewM.copy(m);
	}
	
	public function loadProjectionMatrix(m:Mat44):Void
	{
		projM.copy(m);
	}
	
	public function getWorldMatrix(m:Mat44):Void
	{
		m.copy(worldM);
	}
	
	public function getViewMatrix(m:Mat44):Void
	{
		m.copy(viewM);
	}
	
	public function getProjectionMatrix(m:Mat44):Void
	{
		m.copy(projM);
	}
	
	private function setProgramConstantsMatrix(type:Context3DProgramType, index:Int, m:Mat44):Void
	{
		up[0] = m.e00;
		up[1] = m.e01;
		up[2] = m.e02;
		up[3] = m.e03;
		c3d.setProgramConstantsFromVector(type, index, up);
		up[0] = m.e10;
		up[1] = m.e11;
		up[2] = m.e12;
		up[3] = m.e13;
		c3d.setProgramConstantsFromVector(type, index + 1, up);
		up[0] = m.e20;
		up[1] = m.e21;
		up[2] = m.e22;
		up[3] = m.e23;
		c3d.setProgramConstantsFromVector(type, index + 2, up);
		up[0] = m.e30;
		up[1] = m.e31;
		up[2] = m.e32;
		up[3] = m.e33;
		c3d.setProgramConstantsFromVector(type, index + 3, up);
	}
	
	private inline function setProgramConstantsNumber(type:Context3DProgramType, index:Int, x:Float, y:Float, z:Float, w:Float):Void
	{
		up[0] = x;
		up[1] = y;
		up[2] = z;
		up[3] = w;
		c3d.setProgramConstantsFromVector(type, index, up);
	}
	
	private function createBasicVertexShaderCode(vertexPositionIndex:Int, vertexNormalIndex:Int):String
	{
		var pos:String = "v" + vertexPositionIndex;
		var nor:String = "v" + vertexNormalIndex;
		var code:String = "m44 vt0, va0, vc0; \n" + "mov " + pos + ", vt0; \n" + "m44 op, vt0, vc4; \n" + "m33 vt0.xyz, va1, vc0; \n" + "nrm vt0.xyz, vt0.xyz; \n" + "mov " + nor + " vt0; \n";
		return code;
	}
	
	private function createBasicFragmentShaderCode(vertexPositionIndex:Int, vertexNormalIndex:Int, programColorIndex:Int, programAmbDifEmiIndex:Int, programSpcShnIndex:Int, programAmbLightColorIndex:Int, programDirLightColorIndex:Int, programDirLightDirectionIndex:Int, programCameraPosIndex:Int):String
	{
		var pos:String = "v" + vertexPositionIndex;
		var nor:String = "v" + vertexNormalIndex;
		var col:String = "fc" + programColorIndex;
		var mat:String = "fc" + programAmbDifEmiIndex;
		var spc:String = "fc" + programSpcShnIndex;
		var alc:String = "fc" + programAmbLightColorIndex;
		var dlc:String = "fc" + programDirLightColorIndex;
		var dld:String = "fc" + programDirLightDirectionIndex;
		var cam:String = "fc" + programCameraPosIndex;
		var code:String = "nrm ft1.xyz, " + nor + ".xyz \n" + // ft1 = normal
			"mov ft2, " + col + " \n" + // ft2 = col
			"mul ft0, ft2, " + alc + " \n" + // ft0 = ambColor
			"mul ft0, ft0.xyz, " + mat + ".xxx \n" + // ft0 = ft0 * ambFactor
			"mul ft3, ft2.xyz, " + mat + ".zzz \n" + // ft3 = col * emiFactor
			"add ft0, ft0, ft3 \n" + // ft0 = ft0 + ft3
			"mul ft3, ft2, " + dlc + " \n" + // ft3 = dirColor
			"mul ft3, ft3.xyz, " + mat + ".yyy \n" + // ft3 = ft2 * dirFactor
			"mov ft4, " + dld + " \n" + // ft4 = lightDir
			"neg ft4, ft4 \n" + // ft4 = -ft4
			"nrm ft4.xyz, ft4.xyz \n" + // ft4 = nrm(ft4)
			"dp3 ft0.w, ft1.xyz, ft4.xyz \n" + // dot = normal * lightDir
			"sat ft0.w, ft0.w \n" + // dot = sat(dot)
			"mul ft3, ft3.xyz, ft0.www \n" + // ft3 = ft3 * dot
			"add ft0, ft0, ft3 \n" + // ft0 = ft0 + ft3
			"mul ft3, ft1.xyz, ft0.www \n" + // ft3 = normal * dot
			"add ft3, ft3, ft3 \n" + // ft3 = ft3 * 2
			"sub ft3, ft3, ft4 \n" + // ft3 = ft3 - lightDir
			"nrm ft3.xyz, ft3.xyz \n" + // ft3 = nrm(ft3)
			"mov ft5, " + cam + " \n" + // ft5 = cam
			"sub ft5, ft5, " + pos + " \n" + // ft5 = ft5 - pos
			"nrm ft5.xyz, ft5.xyz \n" + // ft5 = nrm(ft5)
			"dp3 ft3.w, ft3.xyz, ft5.xyz \n" + // ref = ft3 * ft5
			"sat ft3.w, ft3.w \n" + // ref = sat(ref)
			"pow ft3.w, ft3.w, " + spc + ".yyy \n" + // ref = ref ^ shn
			"mul ft3, ft3.www, " + dlc + ".xyz \n" + // rfc = ref * dirColor
			"mul ft3, ft3, " + spc + ".xxx \n" + // rfc = rfc * spc
			"sub ft3.w, ft3.w, ft3.w \n" + // zer = zer - zer
			"slt ft3.w, ft3.w, ft0.w \n" + // zer = zer < dot ? 1 : 0
			"mul ft3, ft3, ft3.www \n" + // rfc = rfc * zer
			"add ft0, ft0, ft3 \n" + // ft0 = ft0 + rfc
			"mov ft0.w, ft2.w \n" + // ft0 = alp
			"mov oc, ft0 \n" // col = ft0
		;
		return code;
	}

}