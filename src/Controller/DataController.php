<?php declare(strict_types=1);

namespace App\Controller;

use App\Repository\DataRepositoryInterface;
use App\Service\DataService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

class DataController extends AbstractController
{
    public function __construct(
        private DataService $service,
        private DataRepositoryInterface $repository
    ) {}

    #[Route('/data', name: 'data')]
    public function index(): Response
    {
        return $this->json($this->service->getData('error'));
    }

    #[Route('/create', name: 'create')]
    public function create(): Response
    {
        return $this->json($this->repository->insert(
            ['newdata']
        ));
    }
}
