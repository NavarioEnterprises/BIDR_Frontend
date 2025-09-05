from rest_framework import viewsets, status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.http import JsonResponse
from .models import PaymentGateway
from .serializers import PaymentGatewaySerializer


class PaymentGatewayViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing payment gateways
    """
    queryset = PaymentGateway.objects.all()
    serializer_class = PaymentGatewaySerializer
    
    def get_queryset(self):
        queryset = PaymentGateway.objects.all()
        is_active = self.request.query_params.get('is_active')
        if is_active is not None:
            queryset = queryset.filter(is_active=is_active.lower() == 'true')
        return queryset


@api_view(['GET'])
def health_check(request):
    """
    Health check endpoint for the payment service
    """
    return Response({
        'status': 'healthy',
        'service': 'BIDR Payment Service',
        'version': '1.0.0'
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
def service_info(request):
    """
    Service information endpoint
    """
    return Response({
        'service_name': 'BIDR Payment Service',
        'version': '1.0.0',
        'description': 'Secure payment processing with escrow and PIN verification',
        'features': [
            'Paystack Integration',
            'Escrow Management',
            'PIN Verification',
            'Transaction Logging',
            'Refund Processing'
        ],
        'endpoints': {
            'health': '/api/v1/health/',
            'payments': '/api/v1/payments/',
            'transactions': '/api/v1/transactions/',
            'escrow': '/api/v1/escrow/'
        }
    }, status=status.HTTP_200_OK)
